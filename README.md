# ipinfo

# Create a powershell script which meets the following criteria:
#Accepts an IP Address as an Input Parameter<br/>
#Prompt for the IP if it isn't given as a commandline option<br/>
#Enforce that the input is a Valid, internet-routable IP address and tell the user if it's not<br/>
#Output the number of hops between the computer running the script and the input IP<br/>
#Output the average latency of 10 pings to the IP<br/>
# Give information about the IP entered in a friendly manner (sentences):
#Owner of the netblock<br/>
#Geo-location information<br/>
#What ISP, who owns the AS Number, etc<br/>
#Local time and Weather for the Geo-Loc of the IP<br/>
#An optional second commandline parameter to the script that instead outputs all the requested info as a JSON object
