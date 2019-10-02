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
    virtual void(float statustype) GameStatusChange;
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

void FO_StatTracker :: GameStatusChange(float statusType)
{
    if (statusType != ST_GAMESTART && this.GameID == 0)
        return;

    string endpoint = "GameStatusChange";
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
            eventType = "GameStart";
            event = strcat("\"GameID\": ", ftos(this.GameID), ", \"ServerName\": \"", serverName, "\", \"GameTime\": ", ftos(gameTime), ",");
            event = strcat(event, "\"EventType\": \"", eventType, "\", \"Map\": \"", mapname, "\", \"Initiator\": \"world\"");
            this.GameStartReqID = this.RequestID;
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