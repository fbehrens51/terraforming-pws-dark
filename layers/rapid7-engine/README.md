# Rapid7 Scan Engine(s)


https://docs.rapid7.com/nexpose/nexpose-scan-engine-pre-authorized-ami/#deploy-an-aws-scan-engine-using-the-marketplace-cloudformation-template

## CloudFormation template
At the time of the creation of the rapid7-engine layer, it did not work correctly in our configuration.  I found a small reference to this fact (but now I can't find it).

We could try this again

## UserData/Marketplace AMI
We could try this.


## Current/Manual process (post instance launch)

https://docs.rapid7.com/insightvm/configuring-distributed-scan-engines

* ssh to the engine : `ssh ci_rapid7_engine_1`
* Pull down the installer and checksum, then validate and add executable permissions on the file
    ```sh
    sudo -i
    wget https://download2.rapid7.com/download/InsightVM/Rapid7Setup-Linux64.bin
    wget https://download2.rapid7.com/download/InsightVM/Rapid7Setup-Linux64.bin.sha512sum
    sha512sum -c Rapid7Setup-Linux64.bin.sha512sum
    chmod +x Rapid7Setup-Linux64.bin
    ```

* Run the installer
    ```shell
    ./Rapid7Setup-Linux64.bin -c
    ```

* It will prompt for a variety of information (this may be out of order) - we could see if it will support using a response file or another way to answer it's prompts
  * Engine only
  * Console to Engine
    * we could try engine to console next time we can spend some time on this
  * Do not connect to InsightVM (we need connection to our Security Console only)
  * Name, company name
  * Keep other defaults (e.g. install directory of /opt/rapid7,...)
  
* start the service (double check name, the output of the install spits it out)
    ```shell
    systemctl restart nexposeengine.service
    ```

* registration of engine in Security Console
  * via Security Console:
    * click on Administration on the left hand menu
    * Under Scan Options, click on the Manage link next to Engines
    * If replacing an engine, delete existing engine
      * Can't register the same IP twice
      * It will give a signature error if you try to refresh the entry vs deleting and re-adding
        * We could investigate this further
    * Click `New Engine`
    * Enter Name and Address & click Save
  * SSH to engine
    * `sudo -i`
    * `vi /opt/rapid7/nexpose/nse/conf/consoles.xml` (file will appear shortly after registering engine via console)
      * update enabled attribute on entry for our console from `0` to `1`
    * `systemctl restart nexposeengine.service`

