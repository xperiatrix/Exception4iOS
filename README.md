# Exception4iOS
Cutomized prevent App-Crashing solution for iOS based on Signal and RunLoop.

* Handle with exceptions on iOS based on signals and RunLoop.  
  When App is about to crash, it recieved the signals sent from iOS-System, and current RunLoop on the thread will exit immediately(CRASH!). What we can make a better way to exit, is to setting-up a new parallel level RunLoop and fetch all modes, input-sources, timers...etc from the previous RunLoop which will be terminated, and then we put all those stuffs into our new parallel level RunLoop for holding a second for user interface. That will make sence that the App is not crashing for normal users.   
  ![](./Images/AlertView4Crash.PNG)  
  ![](./Images/MakeACrashManully.png)  
  <b>Best practices: You can upload the detail crash info to server once the exception caught or the next launching the App(Cool-Launching). At the parallel solution for handing exception, we should pay more attention both on logging event and collecting statistics.</b>  
  
  

* Handle with crashes those cannot be caught by signals. (To Be Continued Improving)  
  + Out of Memory  
  + Launching OverTime  
  + Background Task Timeout  
  + MainThread Task OverFitting Threshold (watchdog)
