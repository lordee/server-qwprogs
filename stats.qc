// ent to submit stats every x seconds
// server address specified in info
// test if server available

/*
send:
api version?


// start of game/register
server name
team names
player names

// in game stats
kill
death
damage done
shot fired
shot hit (damage done)
touches
caps
kill on flag carrier
time

// chat log?

*/
string GetWeaponName(float code);

string statTrackerURL;
float statTrackerRequestID;

void StatTrackerPostData(string postData)
{
    //uri_post(url, reqID, "application/x-www-form-urlencoded", uri_escape(postData));
    dprint(strcat(postData,"\n"));
    // globals for now because i hate myself
    statTrackerRequestID = statTrackerRequestID + 1;
}

void StatTrackerPlayerStart(entity player)
{
 	if (canLog == 0)
		return;

	local string event;
	event = sprintf(",\n{\"type\": \"playerStart\", \"player\": \"%s\", \"classtime\": %s, \"time\": %s, \"gameTimeStamp\": %s}", player.netname, ftos(player.classtime), ftos(gametime), ftos(time));
	StatTrackerPostData(event);
}

void StatTrackerGoal(entity player)
{
	if (canLog == 0)
		return;
	local string event;
	event = sprintf(",\n{\"type\": \"goal\", \"attacker\": \"%s\", \"time\": %s, \"gameTimeStamp\": %s}", player.netname, ftos(gametime), ftos(time));
	StatTrackerPostData(event);
}

void StatTrackerFumble(entity player)
{
	if (canLog == 0)
		return;
	local string event;
	event = sprintf(",\n{\"type\": \"fumble\", \"attacker\": \"%s\", \"time\": %s, \"gameTimeStamp\": %s}", player.netname, ftos(gametime), ftos(time));
	StatTrackerPostData(event);
}

// TODO this isn't used anywhere -- map end, map change, quad/clan end
void  StatTrackerGameEnd()
{
	if (canLog == 0)
		return;
	local string event;
	event = sprintf(",\n{\"type\": \"gameEnd\", \"time\": %s, \"gameTimeStamp\": %s}", ftos(gametime), ftos(time));
	StatTrackerPostData(event);
}
// TODO this isn't used anywhere
string GetTeamName(float team_no);

void StatTrackerTeamScores()
{
	local float win_score = 0;
	local float winning_team = 0;

	if (team1score > win_score) {
		win_score = team1score;
		winning_team = 1;
	}
	
	if (team2score > win_score) {
		win_score = team2score;
		winning_team = 2;
	}
	else if (team2score == win_score) {
		winning_team = 0;
	}

	if (team3score > win_score) {
		win_score = team3score;
		winning_team = 3;
	}
	else if (team3score == win_score) {
		winning_team = 0;
	}

	if (team4score > win_score) {
		win_score = team4score;
		winning_team = 4;
	}
	else if (team4score == win_score) {
		winning_team = 0;
	}

	local string teamscores;
	teamscores = sprintf("\"team1Score\": %s", ftos(team1score));
	if (number_of_teams > 1)
		teamscores = strcat(teamscores, sprintf(", \"team2Score\": %s", ftos(team2score)));
	if (number_of_teams > 2)
		teamscores = strcat(teamscores, sprintf(", \"team3Score\": %s", ftos(team3score)));
	if (number_of_teams > 3)
		teamscores = strcat(teamscores, sprintf(", \"team4Score\": %s", ftos(team4score)));

	local string teamnames;
	teamnames = sprintf("\"team1Name\": \"%s\"", GetTeamName(1));
	if (number_of_teams > 1)
		teamnames = strcat(teamnames, sprintf(", \"team2Name\": \"%s\"", GetTeamName(2)));
	if (number_of_teams > 2)
		teamnames = strcat(teamnames, sprintf(", \"team3Name\": \"%s\"", GetTeamName(3)));
	if (number_of_teams > 3)
		teamnames = strcat(teamnames, sprintf(", \"team4Name\": \"%s\"", GetTeamName(4)));

	local string event;
	event = sprintf(",\n{\"type\": \"teamScores\", %s, %s, \"winningTeam\": %s, \"time\": %s, \"gameTimeStamp\": %s}", teamscores, teamnames, ftos(winning_team), ftos(gametime), ftos(time));
	StatTrackerPostData(event);
}

void StatTrackerAttack(entity attacker)
{
	if (canLog == 0)
		return;
	local string event;
	event = sprintf(",\n{\"type\": \"attack\", \"attacker\": \"%s\", \"inflictor\": \"%s\", \"time\": %s, \"gameTimeStamp\": %s}", attacker.netname, GetWeaponName(attacker.current_weapon), ftos(gametime), ftos(time));
	StatTrackerPostData(event);
}

void StatTrackerChangeClass(entity player, float previous, float next)
{
	if (canLog == 0)
		return;

    float timeplayed;
    timeplayed = gametime - player.classtime;

	local string event;
	event = sprintf(",\n{\"type\": \"changeClass\", \"player\": \"%s\", \"previousClass\": %s, \"nextClass\": %s, \"team\": %s, \"timePlayed\": %s, \"time\": %s, \"gameTimeStamp\": %s}",
							player.netname,
							ftos(previous),
							ftos(next),
							ftos(player.team_no),
							ftos(timeplayed),
							ftos(gametime),
							ftos(time)
							);
	StatTrackerPostData(event);
}

void StatTrackerDamage(entity target, entity inflictor, entity attacker, float damage)
{
    if (canLog == 0)
		return;

	local string event;
	local string part1;
	local string part2;
	local string damageKind;
	local string attackername;
	local string targetname;
	local string inflictorId;

	attackername = attacker.netname;
	targetname = target.netname;
	if (attacker == target)
		damageKind = "self";
	else if (attacker.team_no == target.team_no)
		damageKind = "team";
	else
		damageKind = "enemy";

	if (inflictor.classname == "player") 
		inflictorId = GetWeaponName(attacker.current_weapon);
	else {
		inflictorId = inflictor.classname;
		if ((inflictor.classname == "spike") && (attacker.playerclass == 3)) {
			inflictorId = "nailgrenspike";
		}
		else if ((inflictor.classname == "spike") && (attacker.playerclass == 5)) {
			inflictorId = "superspike";
		}
		if (inflictorId == "worldspawn")
			attackername = "world";
		else if (inflictorId == "building_sentrygun") {
			attackername = attacker.real_owner.netname;
			if (damageKind == "damageTeam")
				return;
		}
		else if ((inflictorId == "grenade") && (inflictor.grenadename != ""))
			inflictorId = inflictor.grenadename;
	}

	if (target.netname != "") {
		part1 = sprintf(",\n{\"type\": \"damage\", \"kind\": \"%s\", \"attacker\": \"%s\", \"attackerClass\": %s, \"attackerTeam\": %s, \"target\": \"%s\", \"targetClass\": %s, \"targetTeam\": %s, ",
						damageKind, 
						attackername, 
					   	ftos(attacker.playerclass), 
					   	ftos(attacker.team_no), 
					   	target.netname, 
					   	ftos(target.playerclass), 
					   	ftos(target.team_no));
		part2 = sprintf("\"inflictor\": \"%s\", \"damage\": %s, \"time\": %s, \"gameTimeStamp\": %s}", 
						inflictorId,
						ftos(damage),
						ftos(gametime),
						ftos(time)
						);

		event = strcat(part1, part2);
		StatTrackerPostData(event);
	}
}

void StatTrackerKill(entity attacker, entity target, entity inflictor)
{
	if (canLog == 0)
		return;

	if ((target.classname != "player") && (target.classname != "building_sentrygun"))
		return;
	
	local string killKind;
	local string attackername;
	local string targetname;
	local string inflictorId;

	attackername = attacker.netname;
	targetname = target.netname;
	if (attacker == target)
		killKind = "self";
	else if (attacker.team_no == target.team_no)
		killKind = "team";
	else
		killKind = "enemy";

	if (inflictor.classname == "player") 
		inflictorId = GetWeaponName(attacker.current_weapon);
	else {
		inflictorId = inflictor.classname;
		if (inflictorId == "worldspawn")
			attackername = "world";
		else if (inflictorId == "building_sentrygun")
			attackername = attacker.real_owner.netname;
		else if ((inflictorId == "grenade") && (inflictor.grenadename != ""))
			inflictorId = inflictor.grenadename;
	}

	local string event;
	local string part1;
	local string part2;

	part1 = sprintf(",\n{\"type\": \"kill\", \"kind\": \"%s\", \"attacker\": \"%s\", \"attackerClass\": %s, \"attackerTeam\": %s, \"target\": \"%s\", \"targetClass\": %s, \"targetTeam\": %s, ",
					killKind,
					attackername, 
				   	ftos(attacker.playerclass), 
				   	ftos(attacker.team_no), 
				   	targetname, 
				   	ftos(target.playerclass), 
				   	ftos(target.team_no));
	part2 = sprintf("\"inflictor\": \"%s\", \"time\": %s, \"gameTimeStamp\": %s}", 
					inflictorId,					
					ftos(gametime),
					ftos(time)
					);

	event = strcat(part1, part2);
	StatTrackerPostData(event);
}

void StatTrackerGameStart()
{
 	if (canLog == 0)
		return;
	local string event;
	local entity player;
	local float numplayers = 0;
	player = find (world, classname, "player");	

	while (player) 
	{
		numplayers++;
		player = find (player, classname, "player");
	}

	event = sprintf("{\"type\": \"gameStart\", \"map\": \"%s\", \"numPlayers\": %s, \"numTeams\": %s, \"time\": %s, \"gameTimeStamp\": %s}", mapname, ftos(numplayers), ftos(number_of_teams), ftos(gametime), ftos(time));
	StatTrackerPostData(event);
}

// TODO this isn't used, we want to json it and change when it's called/integrate with gamestart
/*
void StatTrackerRegisterGame(string url, float reqID)
{
    string postData;
    postData = StatTrackerBuildPostData(postData, "time", ftos(time));
    postData = StatTrackerBuildPostData(postData, "transtype", "RegisterGame");
    string hn = infokey(world, "hostname");
    if (hn)
    {
        postData = StatTrackerBuildPostData(postData, "servername", hn);
    }
    
    postData = StatTrackerBuildPostData(postData, "mapname", mapname);
    
    // team names
    for (float i = 1; i <= number_of_teams; i = i + 1)
    {
        postData = StatTrackerBuildPostData(postData, strcat("team", ftos(i)), GetTeamName(i));
    }

    StatTrackerPostData(postData);

    // players
    entity p;
    p = find(world, classname, "player");
    while (p)
    {
        postData = "";
        postData = StatTrackerBuildPostData(postData, "time", ftos(time));
        postData = StatTrackerBuildPostData(postData, "transtype", "RegisterPlayer");
        postData = StatTrackerBuildPostData(postData, "name", p.netname);
        postData = StatTrackerBuildPostData(postData, "playerid", ftos(p.tf_id));
        postData = StatTrackerBuildPostData(postData, "team", ftos(p.team_no));
        postData = StatTrackerBuildPostData(postData, "class", TeamFortress_GetClassName(p.playerclass));

        StatTrackerPostData(url, reqID, postData);
        p = find(p, classname, "player");
    }
}
*/
void(float reqID, float responseCode, string resourceBody) URI_Get_Callback = {
    if (responseCode != 200)
    {
        dprint("Stats server not contactable\n");
        dprint("Response Code: ", ftos(responseCode), "\n");
        dprint("Resource Body:\n", resourceBody,"\n");
    }
    else
    {
        
    }
    
}

void StatTrackerStart() 
{
    // TODO - test for settings to indicate if we track for all games etc (quad, clan, pub)
    statTrackerURL = infokey(world, "stattracker_url");
    if (!statTrackerURL)
    {
        statTrackerURL = "http://localhost:80";
    }
    statTrackerRequestID = 1;

    //StatTrackerRegisterGame(statTrackerURL, statTrackerRequestID);
}

// TODO - not used currently
void MapEndSequence()
{
	local entity player;
	player = find (world, classname, "player");	
	while (player) 
	{
		if (player.playerclass != 0) {
			StatTrackerChangeClass(player, player.playerclass, PC_UNDEFINED);
			player.classtime = gametime;
		}
		player = find (player, classname, "player");
	}
	StatTrackerTeamScores();
	StatTrackerGameEnd();
	canLog = 0;
}