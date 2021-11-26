package com.artinoise.flutter_midiplayer;

import android.content.Context;
import android.media.MediaPlayer;
import android.media.PlaybackParams;
import android.net.Uri;
import android.os.Build;
import androidx.annotation.NonNull;

import java.io.File;
import java.io.IOException;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.util.PathUtils;
import android.util.Log;

/** FlutterMidiplayerPlugin */
public class FlutterMidiplayerPlugin implements FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;
  private MediaPlayer player;
  private Context context;
  private int bpm;
  private float volume = (float) (100/127.0);
  private float speed = (float)1.0;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    context = flutterPluginBinding.getApplicationContext();
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "flutter_midiplayer");
    channel.setMethodCallHandler(this);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if(call.method.equals("LOAD")){
      String path = (String)call.argument("path");
      bpm = call.argument("bpm") == null ? 60 : (int) call.argument("bpm");

      result.success(call.method + " " + path + "bpm: " + bpm);

      //File documentDirectory = context.getFilesDir();
      String documentDirectory = context.getApplicationInfo().dataDir; //PathUtils.getDataDirectory(context);
      player = new MediaPlayer();
      try {
        File d = new File(documentDirectory);
        if(d.isDirectory()) {
          File f = new File(documentDirectory + "/app_flutter/" + path);
          if(f.exists()) {
            player.setDataSource(f.getAbsolutePath());
            player.prepare();
          }
        }
      } catch (IOException e) {
        e.printStackTrace();
      }
    } else if (call.method.equals("START")){
      result.success(call.method);
      try {
        if(player != null){
          if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PlaybackParams pp = player.getPlaybackParams();
            pp.setSpeed((float)speed);
            player.setPlaybackParams(pp);
          } else {
            result.notImplemented();
          }
        }
        player.start();
        player.setVolume(volume,volume);
      } catch (Exception e) {
        e.printStackTrace();
      }
    } else if (call.method.equals("STOP")){
      result.success(call.method);
      try {
        player.stop();
        player.prepare();
      } catch (Exception e) {
        e.printStackTrace();
      }
    } else if (call.method.equals("PAUSE")){
      result.success(call.method);
      player.pause();
    } else if (call.method.equals("POSITION")){
      if (player != null) {
        int ms = player.getCurrentPosition();
        double pos = (double)ms*bpm/60000;
        //Log.i("FlutterMidiplayerPlugin","ms "+ms+" - pos "+pos + " - bpm " + bpm);
        result.success(String.format(java.util.Locale.US,"%.5f",pos));
      } else {
        result.success("0.0");
      }
    } else if (call.method.equals("SETVOLUME")){
      double v = (double)call.argument("volume");
      result.success(call.method + " volume=" + v);
      try {
        if(player != null){
          volume = (float) (v/127.0);
          player.setVolume(volume,volume);
        }
      } catch (Exception e) {
        e.printStackTrace();
      }
    } else if (call.method.equals("SETTEMPO")){
      double rate = (double)call.argument("rate");
      result.success(call.method + " rate=" + rate);
      try {
        speed = (float) (rate/100);
      } catch (Exception e) {
        e.printStackTrace();
      }
    } else if (call.method.equals("SETMETRONOMEVOL")) {

      result.success("Android " + android.os.Build.VERSION.RELEASE);
    } else if (call.method.equals("getPlatformVersion")) {
      result.success("Android " + android.os.Build.VERSION.RELEASE);
    } else {
      result.notImplemented();
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }
}
