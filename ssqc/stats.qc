float statTrackerRequestID;
string statTrackerURL = "https://127.0.0.1:5001/api/SSQCStats";

void StatTrackerPostData(string endpoint, string data)
{
    string url = strcat(statTrackerURL, "/", endpoint);
    // globals for now because i hate myself
    statTrackerRequestID = statTrackerRequestID + 1;
    data = strcat("[{", data, "}]");
    uri_post(url, statTrackerRequestID, "application/x-www-form-urlencoded", uri_escape(data));
    dprint(strcat(url,"\n"));
    //uri_post(url, statTrackerRequestID, "application/json; charset=utf-8", uri_escape(data));
    
    dprint(strcat(data,"\n"));
    
}

void StatTrackerPostData2(string endpoint, string data)
{
    string url = strcat(statTrackerURL, "/", endpoint);
    // globals for now because i hate myself
    statTrackerRequestID = statTrackerRequestID + 1;
    uri_post(url, statTrackerRequestID, "application/x-www-form-urlencoded", uri_escape(data));
    dprint(strcat(url,"\n"));
    //uri_post(url, statTrackerRequestID, "application/json; charset=utf-8", uri_escape(data));
    
    dprint(strcat(data,"\n"));
    
}

void StatTrackerGameStatusChange(float statusType)
{
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
            event = strcat("\"servername\": \"", serverName, "\", \"gametime\": ", ftos(gameTime), ", \"eventtype\": \"", eventType, "\", \"map\": \"", mapname);
            event = strcat(event, "\", \"initiator\": \"world\"");
            
            
            
            
            //StatTrackerPostData(endpoint, event);
            string formstring;
            formstring = "gameid=1111";
            StatTrackerPostData2(endpoint, formstring);
            break;
    }
}


void URI_Get_Callback(float reqid, float responsecode, string resourcebody)
{
    dprint(ftos(responsecode));
    dprint (strcat("\n", resourcebody));
}