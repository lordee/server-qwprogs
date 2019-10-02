enum
{
    ST_GAMESTART
};

class FO_StatTracker
{
    float RequestID;
    string URL;

    void FO_StatTracker; // constructor
    virtual void(float statustype) GameStatusChange;
    virtual void(string endpoint, string data) PostData;
};

FO_StatTracker StatTracker; // global

void FO_StatTracker :: FO_StatTracker(void)
{
    RequestID = 0;
    URL = "http://localhost:5000/api/SSQCStats";
}

void FO_StatTracker :: PostData(string endpoint, string data)
{
    string url = strcat(this.URL, "/", endpoint);
    this.RequestID = this.RequestID + 1;

    data = strcat("{", data, "}");
    
    uri_post(url, this.RequestID, "application/json", data);
    //dprint(strcat(url,"\n"));
    //dprint(strcat(data,"\n"));
}

void FO_StatTracker :: GameStatusChange(float statusType)
{
    string endpoint = "GameStatusChange";
    string event = "";
    string serverName = "";
    serverName = infokey(world, "hostname");
    string eventType = "";
    float gameTime = 0;
    float gameID = 0;

    if (serverName == "")
    {
        serverName = "unnamed";
    }

    switch (statusType)
    {
        case ST_GAMESTART:
            eventType = "GameStart";
            event = strcat("\"GameID\": ", ftos(gameID), ", \"ServerName\": \"", serverName, "\", \"GameTime\": ", ftos(gameTime), ",");
            event = strcat(event, "\"EventType\": \"", eventType, "\", \"Map\": \"", mapname, "\", \"Initiator\": \"world\"");
            
            this.PostData(endpoint, event);
            break;
    }
}

void URI_Get_Callback(float reqid, float responsecode, string resourcebody)
{
    dprint(ftos(responsecode));
    dprint (strcat("\n", resourcebody));
}