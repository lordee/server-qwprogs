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

// TODO maybe change to json at some point
void StatTrackerBuildPostData(string postData, string name, string value)
{
    return strcat(postData, "&", name, "=", value);
}

void StatTrackerPostData(entity st, string postData)
{
    uri_post(st.url, st.reqID, "application/x-www-form-urlencoded", postData);
    st.reqID = st.reqID + 1;
}

void StatTrackerRegisterGame(entity st)
{
    string postData;
    postData = StatTrackerBuildPostData(postData, "time", ftos(time));
    postData = StatTrackerBuildPostData(postData, "transtype", "RegisterGame");
    postData = StatTrackerBuildPostData(postData, "servername", );
    postData = StatTrackerBuildPostData(postData, "mapname", mapname);
    
    // team names
    for (float i = 1; i <= number_of_teams; i = i + 1)
    {
        postData = StatTrackerBuildPostData(postData, strcat("team", ftos(i)), GetTeamName(i));
    }

    StatTrackerPostData(st, postData);

    // players
    // TODO - spectators etc?
    entity p;
    p = find(world, classname, "player");
    while (p)
    {
        postData = "";
        postData = StatTrackerBuildPostData(postData, "time", ftos(time));
        postData = StatTrackerBuildPostData(postData, "transid", st.transid); // TODO is this materially diff to reqid?
        st.transid = st.transid + 1;
        postData = StatTrackerBuildPostData(postData, "transtype", "RegisterPlayer");
        postData = StatTrackerBuildPostData(postData, "name", p.netname);
        postData = StatTrackerBuildPostData(postData, "playerid", ftos(p.tf_id));
        postData = StatTrackerBuildPostData(postData, "team", ftos(p.team_no));
        postData = StatTrackerBuildPostData(postData, "class", TeamFortress_GetClassName(p.playerclass));

        // TODO add transaction to sent pile


        StatTrackerPostData(st, postData);
        p = find(p, classname, "player");
    }
}

void(float reqID, float responseCode, string resourceBody) URI_Get_Callback = {
    if (reqID == 1)
    {
        if (responseCode == 200)
        {
            // got a response, now make ent to submit
            string url = CF_GetSetting("stattracker_url", "stu", "http://localhost:80");
            float statInterval = stof(CF_GetSetting("stattracker_interval", "sti", "5"));
            
            entity st = spawn();
            st.classname = "stattracker";
            st.think = StatTrackerThink;
            st.nextthink = time + statInterval;
            st.cnt2 = statInterval;
            st.url = url; // TODO find a field to use
            st.reqID = 2; // TODO find a field to use
            st.transID = 1;

            // register game
            StatTrackerRegisterGame(st);
        }
        else
        {
            dprint("Stats server not contactable\n");
            dprint("Response Code: ", ftos(responseCode), "\n");
            dprint("Resource Body:\n", resourceBody,"\n");
        }
    }
    else
    {
        if (responseCode != 200)
        {
            dprint("Stats server error\n");
            dprint("Response Code: ", ftos(responseCode), "\n");
            dprint("Resource Body:\n", resourceBody,"\n");

            // TODO put ids back in unsent pile
        }
    }
}

void StatTrackerThink() 
{
    self.nextthink = time + self.cnt2;
    // build formdata
    string postData;

    // TODO should we worry about post size?  Maybe if people actually played

    // TODO put ids in sent pile

    // submit
    StatTrackerPostData(self, postData);
}

void StatTrackerStart() 
{
    // TODO - test for settings to indicate if we track for all games etc (quad, clan, pub)
    string url = CF_GetSetting("stattracker_url", "stu", "http://localhost:80");
    string postData = "start=true";

    // test if we can get a response from server
    uri_post(url, 1, "application/x-www-form-urlencoded", postData);
}