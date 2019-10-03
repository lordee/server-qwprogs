enum
{
    ST_GAMESTART
};

class FO_StatTracker
{
    float RequestID;
    string URL;
    float GameID;
    float GameStartReqID; // used to track request id of game init, so we can set gameid

    void FO_StatTracker; // constructor
    virtual void(float statustype) GameStateChange;
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
    //dprint(strcat(url,"\n"));
    //dprint(strcat(data,"\n"));
}

void FO_StatTracker :: GameStateChange(float statusType)
{
    if (statusType != ST_GAMESTART && this.GameID == 0)
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

    switch (statusType)
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
            p = find(world, classname, "player")
            while(p)
            {
                if (loopCount > 0)
                {
                    event = strcat(event, ", ");
                }
                loopCount = loopCount + 1;

                event = strcat(event, "{\"Name\":\"", p.netname, "\", \"Team\":", ftos(p.team_no), ", \"Class\":", ftos(p.playerclass), "}");
                p = find(p, classname, "player");
            }
            event = strcat(event, "]");

            // specs
            loopCount = 0;
            event = strcat(event, ", \"Spectators\": [");
            p = find(world, classname, "observer");

            while(p)
            {
                if (loopCount > 0)
                {
                    event = strcat(event, ", ");
                }
                loopCount = loopCount + 1;

                event = strcat(event, "{\"Name\":\"", p.netname, "\"}");
                p = find(p, classname, "observer");
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