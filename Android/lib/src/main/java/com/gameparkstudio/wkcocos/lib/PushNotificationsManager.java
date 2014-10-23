package com.gameparkstudio.wkcocos.lib;

import android.app.PendingIntent;
import android.content.Intent;
import android.app.AlarmManager;
import java.lang.System;

//This is a singleton. ref : http://howtodoinjava.com/2012/10/22/singleton-design-pattern-in-java
//when used via getInstance(), it will retrieve the context from the main activity
//This context can be used to launch other activities
public class PushNotificationsManager{

    public String WKTitle;
    public String WKMessage;

    private static class LazyHolder
    {
        private static final PushNotificationsManager INSTANCE = new PushNotificationsManager();
    }

    public static PushNotificationsManager getInstance()
    {
        return LazyHolder.INSTANCE;
    }

    public boolean schedule(long when, String title, String message)
    {
        WKTitle = title;
        WKMessage = message;

        long time = System.currentTimeMillis();

        Intent WKIntent = new Intent(MainActivity.getContext(), MainReceiver.class);
        PendingIntent WKPI = PendingIntent.getBroadcast(MainActivity.getContext(), 0, WKIntent, 0);

        AlarmManager alarmManager = (AlarmManager)MainActivity.getContext().getSystemService(MainActivity.getContext().ALARM_SERVICE);
        alarmManager.set(AlarmManager.RTC, when + time, WKPI);

        return true;
    }
	
}