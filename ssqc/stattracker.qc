enum
{
    ST_GAMESTART,
    ST_CHANGENAME,
    ST_CHANGETEAM,
    ST_CHANGECLASS,
    ST_DISCONNECTED,
    ST_CONNECTED,
    ST_BECAMEPLAYER,
    ST_BECAMESPECTATOR,
    ST_CHAT,
    ST_BROADCAST
};

/*
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

// infokey tf_id always set, not just clan battles?
*/

class FO_StatTracker
{
    float RequestID;
    string URL;
    float GameID;
    float GameStartReqID; // used to track request id of game init, so we can set gameid
    entity PlayerChange; // can't pass ents as args, so track player here for state change

    void FO_StatTracker; // constructor
    virtual void(float stateType) GameStateChange;
    virtual void(float stateType) PlayerStateChange;
    virtual void(float stateType) BroadcastMessage;
    virtual void(string endpoint, string data) PostData;
};

FO_StatTracker StatTracker; // global

void FO_StatTracker :: FO_StatTracker(void)
{
    RequestID = 0;
    URL = "http://localhost:5000/api/SSQCStats";
    GameID = 0;
    GameStartReqID = 0;
}

void FO_StatTracker :: PostData(string endpoint, string data)
{
    string url = strcat(this.URL, "/", endpoint);
    data = strcat("{", data, "}");
    
    uri_post(url, this.RequestID, "application/json", data);

    this.RequestID = this.RequestID + 1;
    dprint(strcat(url,"\n"));
    dprint(strcat(data,"\n"));
}

// todo finish this
void FO_StatTracker :: BroadcastMessage(float stateType)
{
    switch (stateType)
    {
        case ST_CHAT:
            dprint("not implemented");
            break;
        case ST_BROADCAST:
            dprint("not implemented");
            break;
    }
}

void FO_StatTracker :: PlayerStateChange(float stateType)
{
    if (this.GameID == 0)
        return;

    string endpoint = "PlayerStateChange";
    string event = "";
    string eventType = "";
    float gameTime = 0;

    switch (stateType)
    {
        case ST_CHANGENAME:
            eventType = "ChangeName";
            break;
        case ST_CHANGETEAM:
            eventType = "ChangeTeam";
            break;
        case ST_CHANGECLASS:
            eventType = "ChangeClass";
            break;
        case ST_DISCONNECTED:
            eventType = "Disconnected";
            break;
        case ST_CONNECTED:
            eventType = "Connected";
            break;
        case ST_BECAMEPLAYER: // TODO implement
            eventType = "BecamePlayer";
            break;
        case ST_BECAMESPECTATOR: // TODO implement
            eventType = "BecameSpectator";
            break;
    }

    event = strcat("\"GameID\":", ftos(this.GameID), "\"GameTime\":", ftos(gameTime), ", \"EventType\": \"", eventType, "\", \"Player\": {");
    event = strcat(event, "\"TF_ID\":", ftos(this.PlayerChange.tf_id), "\"Name\": \"", this.PlayerChange.netname, "\", \"Team\":", ftos(this.PlayerChange.team_no));
    event = strcat(event, ", \"Class\":", ftos(this.PlayerChange.playerclass), "}");

    this.PostData(endpoint, event);
}

void FO_StatTracker :: GameStateChange(float stateType)
{
    if (stateType != ST_GAMESTART && this.GameID == 0)
        return;

    string endpoint = "GameStateChange";
    string event = "";
    string serverName = "";
    serverName = infokey(world, "hostname");
    string eventType = "";
    float gameTime = 0;

    if (serverName == "")
    {
        serverName = "unnamed";
    }

    switch (stateType)
    {
        case ST_GAMESTART:
            this.GameStartReqID = this.RequestID;
            eventType = "GameStart";
            event = strcat("\"GameID\": ", ftos(this.GameID), ", \"ServerName\": \"", serverName, "\", \"GameTime\": ", ftos(gameTime), ",");
            event = strcat(event, "\"EventType\": \"", eventType, "\", \"Map\": \"", mapname, "\", \"Initiator\": \"world\"");
            // send player info too
            entity p;
            float loopCount = 0;
            event = strcat(event, ", \"Players\": [");
            p = find(world, ::classname, "player");
            while(p)
            {
                if (loopCount > 0)
                {
                    event = strcat(event, ", ");
                }
                loopCount = loopCount + 1;

                event = strcat(event, "\"TF_ID\":", ftos(p.tf_id), "{\"Name\":\"", p.netname, "\", \"Team\":", ftos(p.team_no), ", \"Class\":", ftos(p.playerclass), "}");
                p = find(p, ::classname, "player");
            }
            event = strcat(event, "]");

            // specs
            loopCount = 0;
            event = strcat(event, ", \"Spectators\": [");
            p = find(world, ::classname, "observer");

            while(p)
            {
                if (loopCount > 0)
                {
                    event = strcat(event, ", ");
                }
                loopCount = loopCount + 1;

                event = strcat(event, "{\"Name\":\"", p.netname, "\", \"Team\":", ftos(p.team_no), ", \"Class\":", ftos(p.playerclass), "}");
                p = find(p, ::classname, "observer");
            }
            event = strcat(event, "]");

            this.PostData(endpoint, event);           
            break;
    }
}

void URI_Get_Callback(float reqid, float responsecode, string resourcebody)
{
    dprint(ftos(responsecode));
    dprint (strcat("\n", resourcebody));

    if (StatTracker.GameID == 0)
    {
        if (reqid == StatTracker.GameStartReqID)
            StatTracker.GameID = stof(resourcebody);
    }
}