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

string statTrackerURL;
float statTrackerRequestID;

// TODO maybe change to json at some point with sent/unsent arrays/retry
string StatTrackerBuildPostData(string postData, string name, string value)
{
    if (strlen(postData))
    {
        postData = strcat(postData, "&", name, "=", value);
    }
    else
    {
        postData = strcat(name, "=", value);
    }
    
    return postData;
}

void StatTrackerPostData(string url, float reqID, string postData)
{
    //uri_post(url, reqID, "application/x-www-form-urlencoded", uri_escape(postData));
    dprint(strcat(postData,"\n"));
    // globals for now because i hate myself
    statTrackerRequestID = statTrackerRequestID + 1;
}


void StatTrackerDamage(entity targ, entity inflictor, entity attacker, float damage)
{
    string postData;
    float postTime = time;
    postData = StatTrackerBuildPostData(postData, "time", ftos(postTime));
    postData = StatTrackerBuildPostData(postData, "transtype", "Damage");
    postData = StatTrackerBuildPostData(postData, "targ.classname", targ.classname);
    if (targ.netname)
    {
        postData = StatTrackerBuildPostData(postData, "targ.netname", targ.netname);
    }
    if ((targ.classname == "building_sentrygun")
        || (targ.classname == "building_dispenser"))
    {
        postData = StatTrackerBuildPostData(postData, "targ.owner", targ.real_owner.netname);
    }
    postData = StatTrackerBuildPostData(postData, "inflictor.classname", inflictor.classname);

    postData = StatTrackerBuildPostData(postData, "attacker.classname", attacker.classname);
    if (attacker.netname)
    {
        postData = StatTrackerBuildPostData(postData, "attacker.netname", attacker.netname);
    }
    postData = StatTrackerBuildPostData(postData, "damage", ftos(damage));
    
    StatTrackerPostData(statTrackerURL, statTrackerRequestID, postData);
}


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

    StatTrackerPostData(url, reqID, postData);

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

    StatTrackerRegisterGame(statTrackerURL, statTrackerRequestID);
}