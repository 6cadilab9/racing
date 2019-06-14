/*

					Damage tracking
				Balkan Underground Evolution, LLC
	(created by Balkan Underground Evolution Development Team)
					
	* Copyright (c) 2017, Balkan Underground Evolution, LLC
	*
	* All rights reserved.
	*
	* Redistribution and use in source and binary forms, with or without modification,
	* are not permitted in any case.
	*
	*
	* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
	* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
	* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
	* A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
	* CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
	* EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
	* PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
	* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
	* LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
	* NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
	* SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
#include <YSI\y_hooks>

#define MAX_RACE_EVENTS						50
#define MAX_RACE_CHECKPOINTS				50
#define MAX_RACE_NAME						60
#define MAX_RACE_VEHICLES					30
#define MAX_RACE_PLAYERS					30
#define INVALID_RACE_ID						-1

enum _e_data 
{
	rName[MAX_RACE_NAME],
	rCreator[MAX_PLAYER_NAME],
	rPlayers,
	rRecord,
	rRecordHolder[MAX_PLAYER_NAME],
	Float:rPairX,
	Float:rPairY,
	Float:rPairZ,
	Float:rPairA,
	Float:rOddX,
	Float:rOddY,
	Float:rOddZ,
	Float:rOddA
}

enum _e_temporary_data
{
	tempVehicle,
	tempPrice,
	tempPlayers,
	tempCheckpoints,
	tempraceID,
	tempEntry,
	tempCounter,
	tempTimer,
	tempSafe,
	tempCompleted,
	tempStartedAt
}

enum _e_cp_data
{
	Float:cpX,
	Float:cpY,
	Float:cpZ
}

enum _e_player_data
{
	inRace,
	eCheckpoints,
	Float:beforeRaceX,
	Float:beforeRaceY,
	Float:beforeRaceZ,
	beforeRaceInt,
	beforeRaceVW,
	raceVehicle,
	raceFinishedTime,
	editingRaceID
}

enum _e_vehicle_data
{
	tempVehicle
}

enum _e_creating_data
{
	eventID
}

new RCPData[MAX_RACE_CHECKPOINTS][_e_cp_data],
	RaceData[MAX_RACE_EVENTS][_e_data],
	RaceTemp[_e_temporary_data],
	RacingVehicles[MAX_RACE_VEHICLES][_e_vehicle_data],
	PlayerRaceData[MAX_PLAYERS][_e_player_data],
	RaceCreatingData[MAX_PLAYERS][_e_creating_data],
	Iterator: Racing<MAX_RACE_EVENTS>;

/**
* Reset all preloaded vehiles, set them to invalid.
* Load all races from the database.
*
*/
hook OnGameModeInit()
{
	/**
	* Set all vehicles to invalid
	*
	*/
	for(new i = 0; i < MAX_RACE_VEHICLES; i++) {
		RacingVehicles[i][tempVehicle] = INVALID_VEHICLE_ID;
	}
	RaceTemp[tempraceID] = INVALID_RACE_ID;
	RaceTemp[tempVehicle] = INVALID_VEHICLE_ID;	
	return true;
}

stock LoadRaces()
{
	printf("[LoadRaces] Loading data from database...");
	mysql_tquery(SQLConn, "SELECT * FROM racedata", "LoadRacesQuery", "");
}

forward LoadRacesQuery();
public LoadRacesQuery()
{	
	new rows = cache_num_rows();
	if(rows)
	{
		new loaded, id;
		while(loaded < rows)
		{
			cache_get_value_name_int(loaded, "id", id);
			cache_get_value_name(loaded, "raceName", RaceData[id][rName], MAX_RACE_EVENTS);
			cache_get_value_name(loaded, "raceCreator", RaceData[id][rCreator], MAX_PLAYER_NAME);
			cache_get_value_name(loaded, "raceRecordHolder", RaceData[id][rRecordHolder], MAX_PLAYER_NAME);
			cache_get_value_name_int(loaded, "racePlayers", RaceData[id][rPlayers]);
			cache_get_value_name_int(loaded, "raceRecord",RaceData[id][rRecord]);
			cache_get_value_name_float(loaded, "racePairX", RaceData[id][rPairX]);
			cache_get_value_name_float(loaded, "racePairY", RaceData[id][rPairY]);
			cache_get_value_name_float(loaded, "racePairZ", RaceData[id][rPairZ]);
			cache_get_value_name_float(loaded, "racePairA", RaceData[id][rPairA]);
			cache_get_value_name_float(loaded, "raceOddX", RaceData[id][rOddX]);
			cache_get_value_name_float(loaded, "raceOddY", RaceData[id][rOddY]);
			cache_get_value_name_float(loaded, "raceOddZ", RaceData[id][rOddZ]);
			cache_get_value_name_float(loaded, "raceOddA", RaceData[id][rOddA]);
			loaded ++;
			Iter_Add(Racing, id);
		}
		printf("[LoadRaces] %d races have been loaded!", loaded);
	}
	return true;
}

stock LoadRaceCheckpoints(raceid)
{
	new query[128];
	mysql_format(SQLConn, query, sizeof(query), "SELECT * FROM racecheckpoints WHERE raceID='%d'", raceid);
	mysql_tquery(SQLConn, query, "LoadRaceCheckpointsQuery", "i", raceid);
	return true;
}

forward LoadRaceCheckpointsQuery(raceid);
public LoadRaceCheckpointsQuery(raceid)
{
	new rows = cache_num_rows();
	if(rows)
	{
		new loaded;
		while(loaded < rows)
		{
			cache_get_value_name_float(loaded, "raceX", RCPData[loaded][cpX]);
			cache_get_value_name_float(loaded, "raceY", RCPData[loaded][cpY]);
			cache_get_value_name_float(loaded, "raceZ", RCPData[loaded][cpZ]);
			loaded++;
		}
		printf("Server je ucitao %d checkpointa za race id %d.", loaded, raceid);
		RaceTemp[tempCheckpoints] = loaded;
	}
	return true;
}

stock ResetRacingData()
{
	RaceTemp[tempCheckpoints] = 0;
	RaceTemp[tempPlayers] = 0;
	RaceTemp[tempVehicle] = INVALID_VEHICLE_ID;
	RaceTemp[tempPrice] = 0;
	RaceTemp[tempSafe] = 0;
	RaceTemp[tempCompleted] = 0;
	RaceTemp[tempEntry] = 0;
	RaceTemp[tempraceID] = INVALID_RACE_ID;
	RaceTemp[tempStartedAt] = 0;
	KillTimer(RaceTemp[tempTimer]);

	for(new i = 0; i < MAX_RACE_VEHICLES; i++) {
		if(RacingVehicles[i][tempVehicle] != INVALID_VEHICLE_ID) 
		{
			if(IsValidVehicle(RacingVehicles[i][tempVehicle]))
			{
				if(IsVehicleRaceVehicle(RacingVehicles[i][tempVehicle])) 
				{
					DestroyVehicle(RacingVehicles[i][tempVehicle]);
					printf("%d event veh destroyed", RacingVehicles[i][tempVehicle]);
					RacingVehicles[i][tempVehicle] = INVALID_VEHICLE_ID;
				}
			}
		}
	}
	return true;
}

stock ResetPlayerRacing(playerid)
{
	PlayerRaceData[playerid][inRace] = INVALID_RACE_ID;
	PlayerRaceData[playerid][eCheckpoints] = -1;
	PlayerRaceData[playerid][raceVehicle] = INVALID_VEHICLE_ID;
	PlayerRaceData[playerid][beforeRaceInt] = 0;
	PlayerRaceData[playerid][beforeRaceVW] = 0;
	PlayerRaceData[playerid][raceFinishedTime] = 0;
	DisableRemoteVehicleCollisions(playerid,0);
	return true;
}

/*
* With this method we create new race.
* Get predefined race id store it to the databse.
*/
CreateRace(playerid, raceid)
{
	new query[128];
	mysql_format(SQLConn, query, sizeof(query), "INSERT INTO racedata SET id='%d', raceName='%e', raceCreator='%e', racePlayers='%d'", raceid, RaceData[raceid][rName], pName[playerid], RaceData[raceid][rPlayers]);
	mysql_tquery(SQLConn,query,"","");
	// podesi rekordera na none zbog provjere kad se pridruzi
	format(RaceData[raceid][rRecordHolder], MAX_PLAYER_NAME, "none");
	return true;
}

/**
* With this method here we insert race checkpoint for specific race.
* We get race id, and x,y,z coords.
*/
InsertRaceCheckpoint(raceid, Float:tcX, Float:tcY, Float:tcZ)
{
	new query[128];
	mysql_format(SQLConn,query, sizeof(query), "INSERT INTO racecheckpoints SET raceID='%d', raceX='%f', raceY='%f', raceZ='%f'", raceid, tcX, tcY, tcZ);
	mysql_tquery(SQLConn,query,"","");
	return true;
}

/**
* When the event is started we publish it to the public.
* Display basic info set counter.
*/
stock PublishRaceEvent(playerid, raceid)
{
	new price = RaceTemp[tempPrice], string[190];

	if(price > 0) format(string, sizeof(string), "Utrka %s je zapoceta. Da se prijavite koristite /joinrace! (Cijena ulaza je $%d)", RaceData[raceid][rName], price);
	else format(string, sizeof(string), "Utrka %s je zapoceta. Da se prijavite koristite /joinrace! (Ulaz besplatan)", RaceData[raceid][rName]);
	SendClientMessageToAll(COLOR_GREEN, string);

	/**
	* Set the entry price, counter, and start the timer
	*/
	RaceTemp[tempEntry] = gettime() + 50;
	RaceTemp[tempraceID] = raceid;
	RaceTemp[tempCounter] = 60;
	RaceTemp[tempTimer] = SetTimerEx("OnRaceCounting",1000,true,"i",raceid);

	/**
	* Notify administrators
	*/
	format(string, sizeof(string), "Admcmd: %s je startovao utrku %s; vozilo: %d, ulaz: $%d, rb: %d.", pName[playerid], RaceData[raceid][rName], RaceTemp[tempVehicle], RaceTemp[tempPrice], raceid);
	SendAdminGmMessage(COLOR_LIGHTRED, string);
	return true;
}

forward OnRaceCounting(raceid);
public OnRaceCounting(raceid)
{
	if(raceid != INVALID_RACE_ID) 
	{
		RaceTemp[tempCounter] --;
		new string[128];
		foreach(new i:Player) 
		{
			if(PlayerRaceData[i][inRace] == raceid)
			{
				format(string, sizeof(string), "~g~%d", RaceTemp[tempCounter]);
				GameTextForPlayer(i, string, 1000, 3);
				if(RaceTemp[tempCounter] <= 0) 
				{
					format(string, sizeof(string), "~b~GO! GO! GO!");
					GameTextForPlayer(i, string, 1000, 3);
					SetPlayerRaceCheckpoint(i,0,RCPData[0][cpX],RCPData[0][cpY],RCPData[0][cpZ],RCPData[1][cpX],RCPData[1][cpY],RCPData[1][cpZ],20.0);
					if(IsPlayerInAnyVehicle(i))
					{
						VehicleInfo[GetPlayerVehicleID(i)][vEngine] = 1;
						VehicleInfo[GetPlayerVehicleID(i)][vLights] = 1;
						UpdateVehicleStatus(GetPlayerVehicleID(i));
					}
					TogglePlayerControllable(i,1);
					DisableRemoteVehicleCollisions(i,1);
				}
			}
		}
		if(RaceTemp[tempCounter] <= 0) {
			KillTimer(RaceTemp[tempTimer]);
			RaceTemp[tempStartedAt] = gettime();
		}
	}
	return true;
}

stock PlayerJoinsRace(playerid, eventid)
{
	if(IsPlayerInRace(playerid) != -1) return 1;
	new price = RaceTemp[tempPrice], slot = RaceTemp[tempPlayers], string[128];
	if(price > 0 && SafeGetPlayerMoney(playerid) < price) return Error(playerid, "Nemate dovoljno novca za ulaz na ovu utrku!");
	if(price > 0) {
		SafeGivePlayerMoney(playerid, -RaceTemp[tempPrice]); 
		RaceTemp[tempSafe] += price;
	}
	SetPlayerVirtualWorld(playerid,999);
	PlayerRaceData[playerid][inRace] = eventid;

	if(playerid % 2) {
		RaceData[eventid][rPairX] -= (6 * floatsin(-RaceData[eventid][rPairA], degrees));
		RaceData[eventid][rPairY] -= (6 * floatcos(-RaceData[eventid][rPairA], degrees));
		RacingVehicles[slot][tempVehicle] = CreateVehicle(RaceTemp[tempVehicle],RaceData[eventid][rPairX],RaceData[eventid][rPairY],RaceData[eventid][rPairZ]+2,RaceData[eventid][rPairA],random(128),random(128),3600);
	}
	else {
		RaceData[eventid][rOddX] -= (6 * floatsin(-RaceData[eventid][rOddA], degrees));
		RaceData[eventid][rOddY] -= (6 * floatcos(-RaceData[eventid][rOddA], degrees));		
		RacingVehicles[slot][tempVehicle] = CreateVehicle(RaceTemp[tempVehicle],RaceData[eventid][rOddX],RaceData[eventid][rOddY],RaceData[eventid][rOddZ]+2,RaceData[eventid][rOddA],random(128),random(128),3600);
	}
	SetVehicleVirtualWorld(RacingVehicles[slot][tempVehicle],999);
	VehicleInfo[RacingVehicles[slot][tempVehicle]][vFuel] = 100.0;
	VehicleInfo[RacingVehicles[slot][tempVehicle]][vEngine] = 0;
	UpdateVehicleStatus(RacingVehicles[slot][tempVehicle]);

	// put player in vehicle and shit
	TogglePlayerControllable(playerid,0);
	SetCameraBehindPlayer(playerid);
	FadePlayerScreen(playerid);
	Streamer_Update(playerid);
	SafeSetPlayerPos(playerid, RaceData[eventid][rOddX],RaceData[eventid][rOddY]+10,RaceData[eventid][rOddZ]);
	PutPlayerInVehicle(playerid, RacingVehicles[slot][tempVehicle], 0);
	RaceTemp[tempPlayers]++;
	PlayerRaceData[playerid][raceVehicle] = RacingVehicles[slot][tempVehicle];

	ClearChatbox(playerid, 3);

	format(string, sizeof(string), "Prijavili ste se na utrku %s i vas redni broj je %d.", RaceData[eventid][rName], RaceTemp[tempPlayers]);
	SendClientMessage(playerid, COLOR_GREEN, string);
	format(string, sizeof(string), "Za ovu utrku koristi se vozilo %s i cijena ulaza iznosi $%d.", VehicleNames[RaceTemp[tempVehicle]-400], RaceTemp[tempPrice]);
	SendClientMessage(playerid, COLOR_GREEN, string);

	if(!strcmp(RaceData[eventid][rRecordHolder], "none")) {
		SendClientMessage(playerid, COLOR_GREEN, "Za ovu utrku trenutno ne postoji rekord ukoliko ga oborite dobijate $10000.");
	}
	else {
		format(string, sizeof(string), "Rekord za ovu utrku drzi %s i zavrsio je za %d sek.", RaceData[eventid][rRecordHolder], RaceData[eventid][rRecord]);
		SendClientMessage(playerid, COLOR_GREEN, string);
		SendClientMessage(playerid, COLOR_GREEN, "Ukoliko oborite rekord dobijate $1000.");
	}
	return true;
}

stock IsPlayerInRace(playerid)
{
	return PlayerRaceData[playerid][inRace];
}

stock ResetPlayerRacingData(playerid)
{
	PlayerRaceData[playerid][inRace] = INVALID_RACE_ID;
	PlayerRaceData[playerid][eCheckpoints] = 0;
	PlayerRaceData[playerid][raceVehicle] = INVALID_VEHICLE_ID;
	return true;
}

/**
* Reset player racing data when he connects
*
*/
hook OnPlayerConnect(playerid)
{
	ResetPlayerRacingData(playerid);
	return true;
}

/**
* Check if player is in the racing event.
* If he is check if the vehicle is valid.
* If it is destoy the vehicle and reset player racing data.
*
*/
hook OnPlayerDisconnect(playerid, reason)
{
	if(IsPlayerInRace(playerid) != -1)
	{
		if(PlayerRaceData[playerid][raceVehicle] != INVALID_VEHICLE_ID) {
			if(IsVehicleRaceVehicle(PlayerRaceData[playerid][raceVehicle])) {
				DestroyVehicle(PlayerRaceData[playerid][raceVehicle]);
			}
		}
		ResetPlayerRacingData(playerid);
	}
	return true;
}

/**
* Checkin when player tries to leave event vehicle.
& If detected put him back in the vehicle.
*
*/
hook OnPlayerExitVehicle(playerid, vehicleid)
{
	if(IsPlayerInRace(playerid) != -1)
	{
		if(PlayerRaceData[playerid][raceVehicle] == vehicleid) {
		    PutPlayerInVehicle(playerid, vehicleid, 0);
		    SendClientMessage(playerid,COLOR_GREY,"Ne mozete napustiti vozilo!");
		}
	}
	return true;
}

/**
* Check if the event vehicle died & destroy if completely so it doesn't respawn
*
*/
hook OnVehicleDeath(vehicleid, killerid)
{
	if(IsVehicleRaceVehicle(vehicleid)) {
		DestroyVehicle(vehicleid);
		printf("%d event veh destroyed", vehicleid);
	}
	return true;
}

/**
* Call this hooked method when player enters race checkpoint.
*
*/
hook OnPlayerEnterRaceCheckpoint(playerid)
{
	if(IsPlayerInRace(playerid) != -1) 
	{
		new cpid = PlayerRaceData[playerid][eCheckpoints] + 1;
		if(cpid == RaceTemp[tempCheckpoints]-1) SetPlayerRaceCheckpoint(playerid,1,RCPData[cpid][cpX],RCPData[cpid][cpY],RCPData[cpid][cpZ],RCPData[cpid+1][cpX],RCPData[cpid+1][cpY],RCPData[cpid+1][cpZ],20.0);
		else if(cpid == RaceTemp[tempCheckpoints]) OnPlayerRaceFinish(playerid);
		else SetPlayerRaceCheckpoint(playerid,0,RCPData[cpid][cpX],RCPData[cpid][cpY],RCPData[cpid][cpZ],RCPData[cpid+1][cpX],RCPData[cpid+1][cpY],RCPData[cpid+1][cpZ],20.0);
		PlayerRaceData[playerid][eCheckpoints]++;
	}
	return true;
}

stock OnPlayerRaceFinish(playerid)
{
	if(IsPlayerInRace(playerid) != -1) 
	{
		RaceTemp[tempCompleted]++;
		PlayerRaceData[playerid][raceFinishedTime] = gettime();
		new playerposition = RaceTemp[tempCompleted], string[128], raceid = RaceTemp[tempraceID];
		if(playerposition == 1) 
		{
			format(string, sizeof(string), "[RACING] %s je zavrsio/la utrku na prvom mjestu.", pName[playerid]);
			if(RaceTemp[tempSafe] > 0)	{
				new mstr[64];
				SafeGivePlayerMoney(playerid, RaceTemp[tempSafe]);
				format(mstr, sizeof(mstr), "[RACING] Dobili ste $%d za prvo mjesto.", RaceTemp[tempSafe]);
				SendClientMessage(playerid, COLOR_GREEN, mstr);
			}
			CheckPlayerRaceFinishedTime(raceid, playerid, PlayerRaceData[playerid][raceFinishedTime], RaceTemp[tempStartedAt]);
		}
		else if(playerposition == 2)
		{
			format(string, sizeof(string), "[RACING] %s je zavrsio/la utrku na drugom mjestu.", pName[playerid]);
			if(RaceTemp[tempSafe] > 0)	{
				new mstr[64];
				SafeGivePlayerMoney(playerid, RaceTemp[tempSafe]/2);
				format(mstr, sizeof(mstr), "[RACING] Dobili ste $%d za drugo mjesto.", RaceTemp[tempSafe]/2);
				SendClientMessage(playerid, COLOR_GREEN, mstr);
			}
		}
		else if(playerposition == 3)
		{
			format(string, sizeof(string), "[RACING] %s je zavrsio/la utrku na trecem mjestu.", pName[playerid]);
			if(RaceTemp[tempSafe] > 0)	{
				new mstr[64];
				SafeGivePlayerMoney(playerid, RaceTemp[tempSafe]/3);
				format(mstr, sizeof(mstr), "[RACING] Dobili ste $%d za trece mjesto.", RaceTemp[tempSafe]/3);
				SendClientMessage(playerid, COLOR_GREEN, mstr);
			}
		}
		DisablePlayerRaceCheckpoint(playerid);

		// send finish message to all player
		foreach(new i:Player) {
			if(PlayerRaceData[i][inRace] == raceid) {
				SendClientMessage(i, COLOR_GREEN, string);
			}
		}

		format(string, sizeof(string), "[RACING] Zavrsili ste utrku za %d sek.", PlayerRaceData[playerid][raceFinishedTime]-RaceTemp[tempStartedAt]);
		SendClientMessage(playerid, COLOR_GREEN, string);

		if(playerposition >= 3) {
			foreach(new i:Player) {
				if(IsPlayerInRace(i) != -1) {
					RemovePlayerFromRace(i);
				}
			}
			ResetRacingData();
		}
	}
	return true;
}

stock RemovePlayerFromRace(playerid)
{
	TogglePlayerControllable(playerid,1);
	DisableRemoteVehicleCollisions(playerid,0);
	DisablePlayerRaceCheckpoint(playerid);
	SafeSetPlayerPos(playerid, PlayerRaceData[playerid][beforeRaceX], PlayerRaceData[playerid][beforeRaceY], PlayerRaceData[playerid][beforeRaceZ]);
	SetPlayerInterior(playerid, PlayerRaceData[playerid][beforeRaceInt]);
	SetPlayerVirtualWorld(playerid, PlayerRaceData[playerid][beforeRaceVW]);
	FadePlayerScreen(playerid);
	PlayerPortFreeze(playerid);
	SetCameraBehindPlayer(playerid);
	ResetPlayerRacingData(playerid);

	if(PlayerRaceData[playerid][raceVehicle] != INVALID_VEHICLE_ID) {
		if(IsVehicleRaceVehicle(PlayerRaceData[playerid][raceVehicle])) {
			DestroyVehicle(PlayerRaceData[playerid][raceVehicle]);
		}
	}

	if(RaceTemp[tempPlayers] > 0) RaceTemp[tempPlayers]--;
	return true;
}

stock CheckPlayerRaceFinishedTime(eventid, playerid, finished, started) 
{
	new seconds = finished - started, string[128];
	if(seconds > RaceData[eventid][rRecord]) {
		format(string, sizeof(string), "[RACING] %s je postavio novi rekord za utrku %s koju je zavrsio za %d sek.", pName[playerid], RaceData[eventid], seconds);
		SendClientMessageToAll(COLOR_GREEN, string);
		RaceData[eventid][rRecord] = seconds;
		format(RaceData[eventid][rRecordHolder], MAX_PLAYER_NAME, "%s", pName[playerid]);
		mysql_format(SQLConn,string, sizeof(string), "UPDATE racedata SET raceRecord='%d', raceRecordHolder='%e' WHERE id='%d' LIMIT 1", seconds, pName[playerid], eventid);
		mysql_tquery(SQLConn,string,"","");
		SafeGivePlayerMoney(playerid, 1000);
	}
	return true;
}

stock IsVehicleRaceVehicle(vehicleid)
{
	for(new i = 0; i < MAX_RACE_VEHICLES; i++) {
		if(RacingVehicles[i][tempVehicle] == vehicleid) return true;
 	}
	return false;
}

cmd:races(playerid, params[]) {
	if(PlayerInfo[playerid][pAdmin] < 2) return Error(playerid, "Niste ovlasteni da koristite tu komandu.");
	if(AdminDuty[playerid] == 0) return Error(playerid, "Morate biti na duznosti!");
	new bigstring[1024];
	foreach(new i:Racing) 
	{
		format(bigstring, sizeof(bigstring), "%sid: %d naziv: %s\n", bigstring, i, RaceData[i][rName]);
	}
	ShowDialog(playerid, Show:StaffDialog, DIALOG_STYLE_MSGBOX, "Lista utrka", bigstring, "Ok","");
	return true;
}

cmd:createrace(playerid, params[]) {
	if(PlayerInfo[playerid][pAdmin] < 5) return Error(playerid, "Niste ovlasteni da koristite tu komandu.");
    if(AdminDuty[playerid] == 0) return Error(playerid, "Morate biti na duznosti!");
    new id = Iter_Free(Racing);
    if(id == INVALID_RACE_ID) return Error(playerid, "Nema vise slobodnog mjesta za evente!");
    new racename[MAX_RACE_NAME], players, string[128];
    if(sscanf(params, "is[60]", players, racename)) return Command(playerid, "/createrace [Max. broj igraca] [Ime utrke]");
    if(players > MAX_RACE_PLAYERS) return Error(playerid, "Max. broj igraca je 30!");
    format(RaceData[id][rName], sizeof(racename), "%s", racename);
    RaceData[id][rPlayers] = players;
    CreateRace(playerid, id);
    format(string, sizeof(string), "cRacing: Kreirali ste novu utrku pod idom %d!", id);
   	SendClientMessage(playerid, COLOR_RED, string);
    Iter_Add(Racing, id);
	return true;
}

cmd:deleterace(playerid, params[])
{
	if(PlayerInfo[playerid][pAdmin] < 5) return Error(playerid, "Niste ovlasteni da koristite tu komandu.");
    if(AdminDuty[playerid] == 0) return Error(playerid, "Morate biti na duznosti!");
	new raceid, string[128];
	if(sscanf(params, "i", raceid)) return Command(playerid, "/deleterace [Redni br. utrke]");
  	if(!Iter_Contains(Racing, raceid)) return Error(playerid, "Utrka sa tim rednim brojem ne postoji!");
	if(raceid == RaceTemp[tempraceID]) return Error(playerid, "Ne mozete obrisati utrku koja je u toku!");

	RaceData[raceid][rRecord] = 0;
	RaceData[raceid][rRecordHolder] = EOS;
	RaceData[raceid][rPlayers] = 0;
	RaceData[raceid][rPairX] = 0.0;
	RaceData[raceid][rPairY] = 0.0;
	RaceData[raceid][rPairZ] = 0.0;
	RaceData[raceid][rPairA] = 0.0;
	RaceData[raceid][rOddX] = 0.0;
	RaceData[raceid][rOddY] = 0.0;
	RaceData[raceid][rOddZ] = 0.0;
	RaceData[raceid][rOddA] = 0.0;

	mysql_format(SQLConn,string, sizeof(string), "DELETE FROM racedata WHERE id='%d'", raceid);
	mysql_tquery(SQLConn,string,"","");
	mysql_format(SQLConn,string, sizeof(string), "DELETE FROM racecheckpoints WHERE raceID='%d'", raceid);
	mysql_tquery(SQLConn,string,"","");
	format(string, sizeof(string), "Admcmd: %s je obrisao utrku pod rednim brojem %d.", pName[playerid], raceid);
	SendAdminGmMessage(COLOR_LIGHTRED, string);
	Iter_Remove(Racing, raceid);
	return true;
}

cmd:editrace(playerid, params[]) {
	if(PlayerInfo[playerid][pAdmin] < 5) return Error(playerid, "Niste ovlasteni da koristite tu komandu.");
    if(AdminDuty[playerid] == 0) return Error(playerid, "Morate biti na duznosti!");
	new raceid, string[128];
	if(sscanf(params, "i", raceid)) return Command(playerid, "/editrace [Redni br. utrke]");	
	if(!Iter_Contains(Racing, raceid)) return Error(playerid, "Utrka sa tim rednim brojem ne postoji!");

	PlayerRaceData[playerid][editingRaceID] = raceid;
	format(string, sizeof(string), "Dodaj novi marker\nPrvi start\nDrugi start\nIme utrke");
	ShowDialog(playerid, Show:RacingEditor, DIALOG_STYLE_LIST, "Upravljanje utrkom", string, "Odaberi","Izlaz");
	return true;
}

cmd:loadrace(playerid, params[]) {
	if(PlayerInfo[playerid][pAdmin] < 2) return Error(playerid, "Niste ovlasteni da koristite tu komandu.");
	if(AdminDuty[playerid] == 0) return Error(playerid, "Morate biti na duznosti!");
	if(RaceTemp[tempraceID] != INVALID_RACE_ID) return Error(playerid, "Vec ima pokrenuta utrka!");

	new bigstring[512],
		loaded = 0;

	foreach(new i:Racing) 
	{
		loaded++;
		format(bigstring, sizeof(bigstring), "%s%s\n", bigstring, RaceData[i][rName]);
	}
	
	if(loaded == 0) return Error(playerid, "Nema kreiranih utrka!");
	ShowDialog(playerid, Show:RacingLoader, DIALOG_STYLE_LIST, "Odaberite event", bigstring, "Ucitaj","Izadji");
	return true;
}

cmd:unloadrace(playerid, params[]) {
	if(PlayerInfo[playerid][pAdmin] < 2) return Error(playerid, "Niste ovlasteni da koristite tu komandu.");
	if(AdminDuty[playerid] == 0) return Error(playerid, "Morate biti na duznosti!");
	if(RaceTemp[tempraceID] == INVALID_RACE_ID) return Error(playerid, "Trenutno nema startovane utrke!");

	new string[128];
	format(string, sizeof(string), "Admcmd: %s je zaustavio utrku %s.", pName[playerid], RaceData[RaceTemp[tempraceID]][rName]);
	SendAdminGmMessage(COLOR_LIGHTRED, string);

	foreach(new i:Player) {
		if(IsPlayerInRace(i) != -1) {
			RemovePlayerFromRace(i);
		}
	}
	ResetRacingData();
	return true;
}

cmd:raceinfo(playerid, params[])
{
	if(PlayerInfo[playerid][pAdmin] < 2) return Error(playerid, "Niste ovlasteni da koristite tu komandu.");
	if(AdminDuty[playerid] == 0) return Error(playerid, "Morate biti na duznosti!");
	if(RaceTemp[tempraceID] == INVALID_RACE_ID) return Error(playerid, "Trenutno nema startovane utrke!");
	new string[256], raceid = RaceTemp[tempraceID];
	format(string, sizeof(string), "{FFFFFF}Informacije o trenutnoj utrci:\n\nIme: %s\nPrisutno igraca: %d\nRekord: %d sec\nRekord postavio: %s\nCijena ulaza: $%d\nModel vozila: %d",
	RaceData[raceid][rName], RaceTemp[tempPlayers], RaceData[raceid][rRecord], RaceData[raceid][rRecordHolder], RaceTemp[tempPrice], RaceTemp[tempVehicle]);
	ShowDialog(playerid,Show:StaffDialog,DIALOG_STYLE_MSGBOX,"Race info",string,"OK","");
	return true;
}

cmd:joinrace(playerid, params[])
{
	new eventid = RaceTemp[tempraceID];
	if(pLoggedIn[playerid] == 0) return Error(playerid, "Niste se prijavili!");
	if(RaceTemp[tempraceID] == INVALID_RACE_ID) return Error(playerid, "Trenutno nema startovane utrke!");
	if(IsPlayerInRace(playerid) != -1) return Error(playerid, "Vec ste na eventu!");
    if(PlayerInfo[playerid][pJailed] != 0) return Error(playerid, "Ne mozete ici na event dok ste u zatvoru!");
    if(PlayerInfo[playerid][pMedicTime] != 0) return Error(playerid, "Ne mozete se sada prijaviti na dm event jer ste u bolnici!");
	if(pMaskUse[playerid] == 1) return Error(playerid, "Ne mozete uci na event sa maskom!");
	if(TeamJoined[playerid] != 0) return Error(playerid, "Ne mozete uci na event kada ste vec na dm eventu!");
	if(IsPlayerFreezed(playerid) != 0) return Error(playerid, "Ne mozete sada uci na event, blokirani ste!");
	if(IsPlayerWorking(playerid) != 0) return Error(playerid, "Ne mozete uci na event dok radite, kucajte prvo /zavrsiposao!");
	if(GetPlayerVehicleID(playerid) != 0) return Error(playerid, "Izadjite iz vozila.");
	if(IsDonMapping[playerid] == 1) return Error(playerid, "Ne mozete ici na event/dm dok mapate kucu!");
	if(Selected_Training[playerid] > 0) return Error(playerid, "Ne mozete ici na event/dm dok trenirate!");
	if(WantedLevel[playerid] >= 1) return Error(playerid, "Ne mozete ici na event dok imate wanted level!");
	if(GetPlayerInterior(playerid) != 0) return Error(playerid, "Ne mozete ici na race event dok se nalazite u int-u!");
	if(RaceTemp[tempPlayers] > RaceData[eventid][rPlayers]) return Error(playerid, "Nema vise mjesta na ovom eventu!");
	if(gettime() > RaceTemp[tempEntry]) return Error(playerid, "Vrijeme za ulaz je isteklo!");

	GetPlayerPos(playerid, PlayerRaceData[playerid][beforeRaceX], PlayerRaceData[playerid][beforeRaceY], PlayerRaceData[playerid][beforeRaceZ]);
	PlayerRaceData[playerid][beforeRaceInt] = GetPlayerInterior(playerid);
	PlayerRaceData[playerid][beforeRaceVW] = GetPlayerVirtualWorld(playerid);
	
	PlayerJoinsRace(playerid, eventid);
	return true;
}

cmd:leaverace(playerid, params[])
{
	if(IsPlayerInRace(playerid) == -1) return Error(playerid, "Niste na eventu!");
	RemovePlayerFromRace(playerid);
	Info(playerid, "Napustili ste utrku! Vraceni ste na prethodnu poziciju.");
	return true;
}

Dialog:RacingLoader(playerid,bool:response,listitem,inputtext[])
{
	if(response)
	{
		foreach(new i:Racing)
		{
			if(!strcmp(RaceData[i][rName], inputtext))
			{
				RaceCreatingData[playerid][eventID] = i;
				ShowDialog(playerid, Show:RacingLoaderVehicle, DIALOG_STYLE_INPUT, "Odaberite vozilo", "Unesite ID modela vozila koji ce se koristiti na ovom eventu:","Dalje","Izadji");
				break;
			}
		}
	}
	return true;
}

Dialog:RacingLoaderVehicle(playerid,bool:response,listitem,inputtext[])
{
	if(response)
	{
		new id = RaceCreatingData[playerid][eventID];
		if(id != INVALID_RACE_ID) {
			RaceTemp[tempVehicle] = strval(inputtext);
			ShowDialog(playerid, Show:RacingLoaderPrice, DIALOG_STYLE_INPUT, "Cijena ulaza", "Unesite cijenu ulaza na ovaj event, ukoliko stavite 0 ulaz ce biti besplatan.", "Dalje","Izadji");
		}
	}
	return true;
}

Dialog:RacingLoaderPrice(playerid,bool:response,listitem,inputtext[])
{
	if(response)
	{
		new id = RaceCreatingData[playerid][eventID];
		if(id != INVALID_RACE_ID) {
			RaceTemp[tempPrice] = strval(inputtext);
			LoadRaceCheckpoints(id);
			PublishRaceEvent(playerid, id);
			Info(playerid, "Ucitali ste novu utrku!");
		}		
	}
	return true;
}

Dialog:RacingEditor(playerid,bool:response,listitem,inputtext[]) {
	if(response) {
		new raceid = PlayerRaceData[playerid][editingRaceID];
		if(raceid == INVALID_RACE_ID) return true;
		new string[128];
		new query[190];
		new Float:posX, Float:posY, Float:posZ, Float:posA;
		new vehicleid = GetPlayerVehicleID(playerid);
		GetVehiclePos(vehicleid, posX, posY, posZ);
		GetVehicleZAngle(vehicleid, posA);
		if(!IsPlayerInAnyVehicle(playerid)) return Error(playerid, "Morate biti u vozilu da upravljate utrkom!");
		switch(listitem) {
			case 0: {
				InsertRaceCheckpoint(raceid, posX, posY, posZ);
				format(string, sizeof(string), "Dodali ste novi marker na ovoj poziciji za utrku %s.", RaceData[raceid][rName]);
				Info(playerid, string);
				format(string, sizeof(string), "Dodaj novi marker\nPrvi start\nDrugi start");
				ShowDialog(playerid, Show:RacingEditor, DIALOG_STYLE_LIST, "Upravljanje utrkom", string, "Odaberi","Izlaz");				
			}
			case 1: {
				RaceData[raceid][rPairX] = posX;
				RaceData[raceid][rPairY] = posY;
				RaceData[raceid][rPairZ] = posZ;
				RaceData[raceid][rPairA] = posA;

				// save do db
				mysql_format(SQLConn, query, sizeof(query), "UPDATE racedata SET racePairX='%f', racePairY='%f', racePairZ='%f', racePairA='%f' WHERE id='%d'", posX, posY, posZ, posA, raceid);
				mysql_tquery(SQLConn,query,"","");
				format(string, sizeof(string), "Dodali ste prvu start poziciju za utrku %s.", RaceData[raceid][rName]);
				Info(playerid, string);
				format(string, sizeof(string), "Dodaj novi marker\nPrvi start\nDrugi start");
				ShowDialog(playerid, Show:RacingEditor, DIALOG_STYLE_LIST, "Upravljanje utrkom", string, "Odaberi","Izlaz");	
			}
			case 2: {
				RaceData[raceid][rOddX] = posX;
				RaceData[raceid][rOddY] = posY;
				RaceData[raceid][rOddZ] = posZ;
				RaceData[raceid][rOddA] = posA;

				// save do db
				mysql_format(SQLConn, query, sizeof(query), "UPDATE racedata SET raceOddX='%f', raceOddY='%f', raceOddZ='%f', raceOddA='%f' WHERE id='%d'", posX, posY, posZ, posA, raceid);
				mysql_tquery(SQLConn,query,"","");
				format(string, sizeof(string), "Dodali ste drugu start poziciju za utrku %s.", RaceData[raceid][rName]);
				Info(playerid, string);
				format(string, sizeof(string), "Dodaj novi marker\nPrvi start\nDrugi start");
				ShowDialog(playerid, Show:RacingEditor, DIALOG_STYLE_LIST, "Upravljanje utrkom", string, "Odaberi","Izlaz");
			}
			case 3: {
				if(raceid == INVALID_RACE_ID) return true;
				ShowDialog(playerid, Show:RacingEditorName, DIALOG_STYLE_INPUT, "Upravljanje imenom utrke", "Unesite novo ime za ovu utrku", "Izmjeni","Izlaz");
			}
		}
	}
	else PlayerRaceData[playerid][editingRaceID] = INVALID_RACE_ID;
	return true;
}

Dialog:RacingEditorName(playerid,bool:response,listitem,inputtext[]) 
{
	if (response) 
	{
		new 
			raceid = PlayerRaceData[playerid][editingRaceID],
			name[MAX_RACE_NAME],
			string[128];

		if(raceid == INVALID_RACE_ID) return true;
		if(sscanf(inputtext, "s[60]", name)) return ShowDialog(playerid, Show:RacingEditorName, DIALOG_STYLE_INPUT, "Upravljanje imenom utrke", "Unesite novo ime za ovu utrku", "Izmjeni","Izlaz");
		if(strlen(name) < 5 || strlen(name) > MAX_RACE_NAME) return ShowDialog(playerid, Show:RacingEditorName, DIALOG_STYLE_INPUT, "Upravljanje imenom utrke", "Unesite novo ime za ovu utrku", "Izmjeni","Izlaz");

		format(RaceData[raceid][rName], sizeof(name), "%s", name);

		format(string, sizeof(string), "AdmCmd: %s je promijenio ime utrke (id %d) u %s.", pName[playerid], raceid, name);
		SendAdminMessage(COLOR_LIGHTRED, string);

		mysql_format(SQLConn, string, sizeof(string), "UPDATE racedata SET raceName='%e' WHERE id='%d' LIMIT 1", RaceData[raceid][rName], raceid);
		mysql_tquery(SQLConn, string, "","");
	}
	return true;
}