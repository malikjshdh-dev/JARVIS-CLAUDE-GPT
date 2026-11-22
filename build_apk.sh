#!/usr/bin/env bash
set -e
grep -q 'id="nb"' index.html || { echo 'ERROR: index.html is the OLD version (no NOTES button). Upload the new index.html.'; exit 1; }
mkdir -p app/www
cp index.html app/www/
cd app
npm init -y
npm i @capacitor/core @capacitor/cli @capacitor/android
cat > capacitor.config.json <<'EOF'
{
  "appId": "com.stark.jarvis",
  "appName": "Jarvis",
  "webDir": "www",
  "plugins": { "CapacitorHttp": { "enabled": true } }
}
EOF
npx cap add android
# Shizuku API integration (official Maven Central artifacts)
cat >> android/app/build.gradle <<'EOF'

dependencies {
    implementation "dev.rikka.shizuku:api:13.1.5"
    implementation "dev.rikka.shizuku:provider:13.1.5"
}
EOF
M=android/app/src/main/AndroidManifest.xml
sed -i 's#</activity>#<intent-filter><action android:name="android.intent.action.VIEW"/><category android:name="android.intent.category.DEFAULT"/><category android:name="android.intent.category.BROWSABLE"/><data android:scheme="com.stark.jarvis" android:host="oauth"/></intent-filter></activity>#' $M
sed -i 's#</manifest>#<uses-permission android:name="android.permission.RECORD_AUDIO"/><uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/><uses-permission android:name="android.permission.WRITE_SETTINGS"/><uses-permission android:name="com.android.alarm.permission.SET_ALARM"/><uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/><uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE"/><uses-permission android:name="android.permission.WAKE_LOCK"/><uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/><uses-permission android:name="android.permission.POST_NOTIFICATIONS"/><queries><package android:name="com.spotify.music"/><package android:name="com.whatsapp"/><package android:name="com.whatsapp.w4b"/><intent><action android:name="android.intent.action.MAIN"/><category android:name="android.intent.category.LAUNCHER"/></intent></queries></manifest>#' $M
sed -i 's#</application>#<service android:name=".JarvisAccess" android:exported="false" android:label="Jarvis" android:permission="android.permission.BIND_ACCESSIBILITY_SERVICE"><intent-filter><action android:name="android.accessibilityservice.AccessibilityService"/></intent-filter><meta-data android:name="android.accessibilityservice" android:resource="@xml/accessibility_config"/></service><service android:name=".JarvisVoiceService" android:exported="true" android:permission="android.permission.BIND_VOICE_INTERACTION"><meta-data android:name="android.voice_interaction" android:resource="@xml/interaction_service"/><intent-filter><action android:name="android.service.voice.VoiceInteractionService"/></intent-filter></service><service android:name=".JarvisSessionService" android:exported="true" android:permission="android.permission.BIND_VOICE_INTERACTION"/><service android:name=".JarvisRecognition" android:exported="true"><intent-filter><action android:name="android.speech.RecognitionService"/><category android:name="android.intent.category.DEFAULT"/></intent-filter><meta-data android:name="android.speech" android:resource="@xml/recognition_service"/></service><service android:name=".JarvisNotif" android:exported="true" android:label="Jarvis" android:permission="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE"><intent-filter><action android:name="android.service.notification.NotificationListenerService"/></intent-filter></service><receiver android:name=".ReminderReceiver" android:exported="false"/><receiver android:name=".BootReceiver" android:exported="true"><intent-filter><action android:name="android.intent.action.BOOT_COMPLETED"/></intent-filter></receiver><activity android:name=".PopupActivity" android:exported="false" android:launchMode="singleTask" android:taskAffinity="com.stark.jarvis.popup" android:excludeFromRecents="true" android:theme="@style/JarvisPopup" android:windowSoftInputMode="adjustResize" android:configChanges="orientation|keyboardHidden|keyboard|screenSize|locale|smallestScreenSize|screenLayout|uiMode|navigation|density|fontScale"/><activity android:name=".AssistActivity" android:exported="true" android:excludeFromRecents="true" android:taskAffinity="" android:theme="@android:style/Theme.Translucent.NoTitleBar"><intent-filter><action android:name="android.intent.action.ASSIST"/><category android:name="android.intent.category.DEFAULT"/></intent-filter></activity></application>#' $M
sed -i 's#</application>#<provider android:name="rikka.shizuku.ShizukuProvider" android:authorities="${applicationId}.shizuku" android:multiprocess="false" android:enabled="true" android:exported="true" android:permission="android.permission.INTERACT_ACROSS_USERS_FULL" /></application>#' $M

R=android/app/src/main/res
mkdir -p $R/xml
cat > $R/xml/accessibility_config.xml <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<accessibility-service xmlns:android="http://schemas.android.com/apk/res/android"
    android:accessibilityEventTypes="typeWindowStateChanged|typeWindowContentChanged|typeViewFocused|typeViewScrolled"
    android:accessibilityFeedbackType="feedbackGeneric"
    android:accessibilityFlags="flagReportViewIds|flagIncludeNotImportantViews|flagRetrieveInteractiveWindows"
    android:canRetrieveWindowContent="true"
    android:canPerformGestures="true"
    android:canTakeScreenshot="true"
    android:notificationTimeout="100"
    android:description="@string/a11y_desc" />
EOF
cat > $R/values/jarvis_strings.xml <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="a11y_desc">Lets Jarvis inspect visible interface labels and perform user-requested navigation, taps, scrolling and text entry. It does not read password fields.</string>
</resources>
EOF
cat > $R/values/jarvis_styles.xml <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="JarvisPopup" parent="Theme.AppCompat.NoActionBar">
        <item name="android:windowIsFloating">true</item>
        <item name="android:windowIsTranslucent">true</item>
        <item name="android:windowBackground">@android:color/transparent</item>
        <item name="android:backgroundDimEnabled">false</item>
        <item name="android:windowAnimationStyle">@android:style/Animation.Dialog</item>
    </style>
</resources>
EOF
cat > $R/xml/interaction_service.xml <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<voice-interaction-service xmlns:android="http://schemas.android.com/apk/res/android"
    android:sessionService="com.stark.jarvis.JarvisSessionService"
    android:recognitionService="com.stark.jarvis.JarvisRecognition"
    android:supportsAssist="true" />
EOF
cat > $R/xml/recognition_service.xml <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<recognition-service xmlns:android="http://schemas.android.com/apk/res/android" />
EOF
D=android/app/src/main/java/com/stark/jarvis
mkdir -p $D
cat > $D/MainActivity.java <<'EOF'
package com.stark.jarvis;

import android.content.Intent;
import android.os.Bundle;
import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {
  @Override
  public void onCreate(Bundle savedInstanceState) {
    registerPlugin(JarvisNative.class);
    super.onCreate(savedInstanceState);
    grab(getIntent());
  }

  @Override
  public void onNewIntent(Intent intent) {
    super.onNewIntent(intent);
    grab(intent);
  }

  private void grab(Intent i) {
    if (i != null && i.getData() != null && "com.stark.jarvis".equals(i.getData().getScheme())) {
      JarvisNative.pendingUrl = i.getDataString();
    }
  }
}
EOF
cat > $D/JarvisAccess.java <<'EOF'
package com.stark.jarvis;

import android.accessibilityservice.AccessibilityService;
import android.content.Intent;
import android.graphics.Rect;
import android.graphics.Path;
import android.accessibilityservice.GestureDescription;
import android.os.Handler;
import android.os.Looper;
import android.view.accessibility.AccessibilityEvent;
import android.os.Bundle;
import android.view.accessibility.AccessibilityNodeInfo;
import android.view.accessibility.AccessibilityWindowInfo;
import java.util.ArrayList;
import java.util.List;

public class JarvisAccess extends AccessibilityService {
  static JarvisAccess inst;
  static volatile String task = null;
  static volatile String arg = "";
  static volatile long until = 0;
  private final Handler h = new Handler(Looper.getMainLooper());
  private int stage = 0;
  private long seen = 0;
  private long stageAt = 0;
  private boolean clicked = false;

  @Override protected void onServiceConnected() { inst = this; }
  @Override public void onAccessibilityEvent(AccessibilityEvent e) {}
  @Override public void onInterrupt() {}
  @Override public boolean onUnbind(Intent i) { inst = null; return super.onUnbind(i); }

  static void arm(String t, String a, long ttl) {
    task = t;
    arg = a == null ? "" : a;
    until = System.currentTimeMillis() + ttl;
    final JarvisAccess s = inst;
    if (s != null) {
      s.stage = "direct".equals(arg) ? 1 : 0;
      s.clicked = false;
      s.seen = 0;
      s.stageAt = 0;
      s.h.removeCallbacksAndMessages(null);
      s.h.postDelayed(new Runnable() { public void run() { s.tick(); } }, 700);
    }
  }

  private void tick() {
    if (task == null) return;
    if (System.currentTimeMillis() > until) { task = null; return; }
    boolean done = false;
    try {
      AccessibilityNodeInfo root = getRootInActiveWindow();
      if (root != null && !getPackageName().equals(String.valueOf(root.getPackageName()))) done = step(root);
    } catch (Exception e) { }
    if (done) {
      task = null;
      h.postDelayed(new Runnable() { public void run() { back(); } }, 900);
    } else {
      h.postDelayed(new Runnable() { public void run() { tick(); } }, 500);
    }
  }

  private void back() {
    try {
      Intent i = getPackageManager().getLaunchIntentForPackage(getPackageName());
      if (i != null) {
        i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_REORDER_TO_FRONT);
        startActivity(i);
      }
    } catch (Exception e) { }
  }

  private boolean step(AccessibilityNodeInfo root) {
    String p = String.valueOf(root.getPackageName());
    long now = System.currentTimeMillis();
    if ("wa_send".equals(task)) {
      if (!p.startsWith("com.whatsapp")) return false;
      if (seen == 0) seen = now;
      if (now - seen < 1200) return false;
      List<AccessibilityNodeInfo> l = root.findAccessibilityNodeInfosByViewId(p + ":id/send");
      AccessibilityNodeInfo n = (l != null && !l.isEmpty()) ? l.get(0) : findDesc(root, "send", "kirim");
      return n != null && click(n);
    }
    if ("toggle".equals(task)) {
      if (seen == 0) seen = now;
      if (now - seen < 1200) return false;
      String[] parts = arg.split("\\|", 2);
      if (parts.length != 2) return false;
      AccessibilityNodeInfo sw = findSwitchFor(root, parts[0]);
      if (sw == null) return false;
      boolean want = "on".equalsIgnoreCase(parts[1]);
      if (sw.isChecked() == want) return true;
      return click(sw);
    }
    if ("spotify".equals(task)) {
      if (!p.equals("com.spotify.music")) return false;
      if (seen == 0) seen = now;
      if (stage == 0) {
        if (now - seen < 2500) return false;
        AccessibilityNodeInfo r = firstResult(root);
        if (r != null && click(r)) { stage = 1; stageAt = now; }
        return false;
      }
      boolean direct = "direct".equals(arg);
      if (direct && now - seen < 2800) return false;
      if (now - stageAt < 1800) return false;
      AccessibilityNodeInfo pl = findDesc(root, "play", "shuffle play", "putar");
      if (direct && !clicked) {
        if (pl != null && click(pl)) { clicked = true; stageAt = now; }
        return false;
      }
      if (findDesc(root, "pause") != null) return true;
      if (pl != null && click(pl)) stageAt = now;
      return false;
    }
    return false;
  }

  private boolean click(AccessibilityNodeInfo n) {
    AccessibilityNodeInfo c = n;
    for (int i = 0; i < 6 && c != null; i++) {
      if (c.isClickable() && c.isEnabled()) return c.performAction(AccessibilityNodeInfo.ACTION_CLICK);
      c = c.getParent();
    }
    return false;
  }

  private AccessibilityNodeInfo findDesc(AccessibilityNodeInfo n, String... keys) {
    if (n == null) return null;
    CharSequence d = n.getContentDescription();
    CharSequence t = n.getText();
    for (String k : keys) {
      if ((d != null && d.toString().equalsIgnoreCase(k)) || (t != null && t.toString().equalsIgnoreCase(k))) return n;
    }
    for (int i = 0; i < n.getChildCount(); i++) {
      AccessibilityNodeInfo r = findDesc(n.getChild(i), keys);
      if (r != null) return r;
    }
    return null;
  }

  private void collectSwitches(AccessibilityNodeInfo n, List<AccessibilityNodeInfo> out) {
    if (n == null) return;
    CharSequence cn = n.getClassName();
    if (n.isVisibleToUser() && n.isEnabled() && (n.isCheckable() || (cn != null && cn.toString().contains("Switch")))) out.add(n);
    for (int i = 0; i < n.getChildCount(); i++) collectSwitches(n.getChild(i), out);
  }

  private void collectTargetLabels(AccessibilityNodeInfo n, String target, List<AccessibilityNodeInfo> out) {
    if (n == null) return;
    CharSequence t = n.getText();
    CharSequence d = n.getContentDescription();
    String v = ((t == null ? "" : t.toString()) + " " + (d == null ? "" : d.toString())).toLowerCase();
    boolean match = false;
    if ("wifi".equals(target)) match = v.contains("wi-fi") || v.matches(".*\\bwifi\\b.*") || v.contains("wlan");
    else if ("bluetooth".equals(target)) match = v.contains("bluetooth");
    else if ("location".equals(target)) match = v.contains("location") || v.contains("lokasi");
    else if ("airplane_mode".equals(target)) match = v.contains("airplane") || v.contains("flight mode") || v.contains("mode pesawat");
    if (match) out.add(n);
    for (int i = 0; i < n.getChildCount(); i++) collectTargetLabels(n.getChild(i), target, out);
  }

  private AccessibilityNodeInfo findSwitchFor(AccessibilityNodeInfo root, String target) {
    List<AccessibilityNodeInfo> labels = new ArrayList<AccessibilityNodeInfo>();
    List<AccessibilityNodeInfo> switches = new ArrayList<AccessibilityNodeInfo>();
    collectTargetLabels(root, target == null ? "" : target.toLowerCase(), labels);
    collectSwitches(root, switches);
    if (labels.isEmpty() || switches.isEmpty()) return null;
    AccessibilityNodeInfo best = null;
    double bestDistance = Double.MAX_VALUE;
    for (AccessibilityNodeInfo label : labels) {
      Rect a = new Rect(); label.getBoundsInScreen(a);
      double ax = (a.left + a.right) / 2.0, ay = (a.top + a.bottom) / 2.0;
      for (AccessibilityNodeInfo sw : switches) {
        Rect b = new Rect(); sw.getBoundsInScreen(b);
        double bx = (b.left + b.right) / 2.0, by = (b.top + b.bottom) / 2.0;
        double dx = ax - bx, dy = ay - by;
        double distance = dx * dx + dy * dy;
        if (distance < bestDistance) { bestDistance = distance; best = sw; }
      }
    }
    return best;
  }

  private AccessibilityNodeInfo findSwitch(AccessibilityNodeInfo n) {
    if (n == null) return null;
    CharSequence cn = n.getClassName();
    if (n.isVisibleToUser() && (n.isCheckable() || (cn != null && cn.toString().contains("Switch")))) return n;
    for (int i = 0; i < n.getChildCount(); i++) {
      AccessibilityNodeInfo r = findSwitch(n.getChild(i));
      if (r != null) return r;
    }
    return null;
  }

  private String label(AccessibilityNodeInfo n, int depth) {
    StringBuilder sb = new StringBuilder();
    CharSequence t = n.getText();
    CharSequence c = n.getContentDescription();
    if (t != null) sb.append(t).append(' ');
    if (c != null) sb.append(c).append(' ');
    if (depth > 0) {
      for (int i = 0; i < n.getChildCount(); i++) {
        AccessibilityNodeInfo k = n.getChild(i);
        if (k != null) sb.append(label(k, depth - 1)).append(' ');
      }
    }
    return sb.toString().trim();
  }

  private void collect(AccessibilityNodeInfo n, List<AccessibilityNodeInfo> out) {
    if (n == null) return;
    if (n.isClickable() && n.isVisibleToUser()) out.add(n);
    for (int i = 0; i < n.getChildCount(); i++) collect(n.getChild(i), out);
  }

  private AccessibilityNodeInfo firstResult(AccessibilityNodeInfo root) {
    Rect sr = new Rect();
    root.getBoundsInScreen(sr);
    int H = sr.height();
    int W = sr.width();
    List<AccessibilityNodeInfo> all = new ArrayList<AccessibilityNodeInfo>();
    collect(root, all);
    AccessibilityNodeInfo best = null;
    int bt = Integer.MAX_VALUE;
    for (AccessibilityNodeInfo n : all) {
      Rect b = new Rect();
      n.getBoundsInScreen(b);
      if (b.top < H * 0.22 || b.top > H * 0.8 || b.width() < W * 0.5 || b.height() < H * 0.04) continue;
      String l = label(n, 2).toLowerCase();
      if (l.length() < 3 || l.matches(".*(your library|premium|create|cancel|clear).*")) continue;
      if (b.top < bt) { bt = b.top; best = n; }
    }
    return best;
  }

  String readScreen() {
    StringBuilder sb = new StringBuilder();
    for (AccessibilityWindowInfo w : getWindows()) {
      AccessibilityNodeInfo r = w.getRoot();
      if (r == null || getPackageName().equals(String.valueOf(r.getPackageName()))) continue;
      sb.append("[").append(r.getPackageName()).append("]\n");
      dump(r, sb, 0);
      if (sb.length() > 6000) break;
    }
    if (sb.length() == 0) {
      AccessibilityNodeInfo r = getRootInActiveWindow();
      if (r != null) dump(r, sb, 0);
    }
    return sb.length() > 6000 ? sb.substring(0, 6000) : sb.toString();
  }

  private void dump(AccessibilityNodeInfo n, StringBuilder sb, int d) {
    if (n == null || d > 30 || sb.length() > 6000) return;
    CharSequence t = n.isPassword() ? null : n.getText();
    CharSequence c = n.isPassword() ? null : n.getContentDescription();
    if (t != null && t.length() > 0) sb.append(t).append('\n');
    else if (c != null && c.length() > 0) sb.append(c).append('\n');
    for (int i = 0; i < n.getChildCount(); i++) dump(n.getChild(i), sb, d + 1);
  }

  boolean doGlobal(String a) {
    int g;
    switch (a) {
      case "home": g = GLOBAL_ACTION_HOME; break;
      case "back": g = GLOBAL_ACTION_BACK; break;
      case "recents": g = GLOBAL_ACTION_RECENTS; break;
      case "notifications": g = GLOBAL_ACTION_NOTIFICATIONS; break;
      case "quick_settings": g = GLOBAL_ACTION_QUICK_SETTINGS; break;
      case "power_menu": g = GLOBAL_ACTION_POWER_DIALOG; break;
      case "lock_screen": g = GLOBAL_ACTION_LOCK_SCREEN; break;
      case "screenshot": g = GLOBAL_ACTION_TAKE_SCREENSHOT; break;
      default: return false;
    }
    return performGlobalAction(g);
  }

  boolean tapByText(String t) {
    for (AccessibilityWindowInfo w : getWindows()) {
      AccessibilityNodeInfo r = w.getRoot();
      if (r == null || getPackageName().equals(String.valueOf(r.getPackageName()))) continue;
      List<AccessibilityNodeInfo> l = r.findAccessibilityNodeInfosByText(t);
      if (l != null) {
        for (AccessibilityNodeInfo n : l) {
          if (click(n)) return true;
        }
      }
    }
    return false;
  }

  boolean typeInto(String t) {
    for (AccessibilityWindowInfo w : getWindows()) {
      AccessibilityNodeInfo r = w.getRoot();
      if (r == null || getPackageName().equals(String.valueOf(r.getPackageName()))) continue;
      AccessibilityNodeInfo f = r.findFocus(AccessibilityNodeInfo.FOCUS_INPUT);
      if (f != null && !f.isPassword()) {
        Bundle b = new Bundle();
        b.putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, t);
        return f.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, b);
      }
    }
    return false;
  }

  boolean longClickByText(String text) {
    if (text == null || text.trim().isEmpty()) return false;
    for (AccessibilityWindowInfo w : getWindows()) {
      AccessibilityNodeInfo r = w.getRoot();
      if (r == null || getPackageName().equals(String.valueOf(r.getPackageName()))) continue;
      List<AccessibilityNodeInfo> nodes = r.findAccessibilityNodeInfosByText(text);
      if (nodes == null) continue;
      for (AccessibilityNodeInfo n : nodes) {
        AccessibilityNodeInfo c = n;
        for (int i = 0; i < 6 && c != null; i++, c = c.getParent()) {
          if (c.isEnabled() && c.isLongClickable() && c.performAction(AccessibilityNodeInfo.ACTION_LONG_CLICK)) return true;
        }
      }
    }
    return false;
  }

  boolean scroll(String direction) {
    AccessibilityNodeInfo root = getRootInActiveWindow();
    if (root == null) return false;
    int action = ("up".equalsIgnoreCase(direction) || "backward".equalsIgnoreCase(direction))
      ? AccessibilityNodeInfo.ACTION_SCROLL_BACKWARD : AccessibilityNodeInfo.ACTION_SCROLL_FORWARD;
    return scrollNode(root, action);
  }

  private boolean scrollNode(AccessibilityNodeInfo node, int action) {
    if (node == null) return false;
    if (node.isVisibleToUser() && node.isScrollable() && node.performAction(action)) return true;
    for (int i = node.getChildCount() - 1; i >= 0; i--) {
      if (scrollNode(node.getChild(i), action)) return true;
    }
    return false;
  }

  boolean tapPoint(float x, float y, boolean hold) {
    if (android.os.Build.VERSION.SDK_INT < 24) return false;
    Path path = new Path();
    path.moveTo(x, y);
    GestureDescription.Builder b = new GestureDescription.Builder();
    b.addStroke(new GestureDescription.StrokeDescription(path, 0, hold ? 650 : 90));
    return dispatchGesture(b.build(), null, null);
  }

  String screenTree() {
    StringBuilder out = new StringBuilder();
    AccessibilityNodeInfo root = getRootInActiveWindow();
    if (root == null) return "";
    appendTree(root, out, 0, new int[]{0});
    return out.toString();
  }

  private void appendTree(AccessibilityNodeInfo n, StringBuilder out, int depth, int[] count) {
    if (n == null || depth > 18 || count[0] >= 100 || out.length() > 9000) return;
    count[0]++;
    Rect b = new Rect(); n.getBoundsInScreen(b);
    CharSequence tx = n.isPassword() ? null : n.getText();
    CharSequence cd = n.getContentDescription();
    String label = tx != null ? tx.toString() : (cd != null ? cd.toString() : "");
    if (!label.isEmpty() || n.isClickable() || n.isScrollable()) {
      for (int j = 0; j < Math.min(depth, 12); j++) out.append("  ");
      out.append(label.replace('\n', ' ').replace('\r', ' ')).append(" | ")
        .append(String.valueOf(n.getClassName())).append(" | ")
        .append("bounds=").append(b.left).append(',').append(b.top).append(',').append(b.right).append(',').append(b.bottom)
        .append(" | clickable=").append(n.isClickable()).append(" | scrollable=").append(n.isScrollable()).append('\n');
    }
    for (int i = 0; i < n.getChildCount(); i++) appendTree(n.getChild(i), out, depth + 1, count);
  }
}
EOF
cat > $D/JarvisNative.java <<'EOF'
package com.stark.jarvis;

import android.app.SearchManager;
import android.content.Context;
import android.content.Intent;
import android.hardware.camera2.CameraCharacteristics;
import android.hardware.camera2.CameraManager;
import android.media.AudioManager;
import android.net.Uri;
import android.provider.CalendarContract;
import android.provider.MediaStore;
import android.provider.Settings;
import android.view.KeyEvent;
import android.content.ComponentName;
import android.media.MediaMetadata;
import android.media.session.MediaController;
import android.media.session.MediaSessionManager;
import android.media.session.PlaybackState;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.provider.AlarmClock;
import android.accessibilityservice.AccessibilityService;
import android.app.ActivityManager;
import android.app.Notification;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.IntentFilter;
import android.graphics.Bitmap;
import android.net.ConnectivityManager;
import android.net.Network;
import android.net.NetworkCapabilities;
import android.os.BatteryManager;
import android.os.Build;
import android.os.Environment;
import android.os.StatFs;
import android.service.notification.StatusBarNotification;
import android.util.Base64;
import androidx.core.app.ActivityCompat;
import android.view.Display;
import com.getcapacitor.JSArray;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.util.Arrays;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import java.util.List;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;
import rikka.shizuku.Shizuku;

@CapacitorPlugin(name = "JarvisNative")
public class JarvisNative extends Plugin {
  public static volatile boolean assist = false;
  public static volatile String pendingUrl = null;

  private void go(Intent i, PluginCall c) {
    try {
      i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
      getContext().startActivity(i);
      c.resolve();
    } catch (Exception e) {
      c.reject(String.valueOf(e.getMessage()));
    }
  }

  @PluginMethod
  public void openUrl(PluginCall c) {
    Intent i = new Intent(Intent.ACTION_VIEW, Uri.parse(c.getString("url", "")));
    String p = c.getString("pkg");
    if (p != null && !p.isEmpty()) i.setPackage(p);
    go(i, c);
  }

  @PluginMethod
  public void openSettings(PluginCall c) {
    String p = c.getString("page", "");
    String a;
    switch (p) {
      case "wifi": a = Settings.ACTION_WIFI_SETTINGS; break;
      case "bluetooth": a = Settings.ACTION_BLUETOOTH_SETTINGS; break;
      case "display": a = Settings.ACTION_DISPLAY_SETTINGS; break;
      case "sound": a = Settings.ACTION_SOUND_SETTINGS; break;
      case "battery": a = Settings.ACTION_BATTERY_SAVER_SETTINGS; break;
      case "location": a = Settings.ACTION_LOCATION_SOURCE_SETTINGS; break;
      case "airplane": a = Settings.ACTION_AIRPLANE_MODE_SETTINGS; break;
      case "apps": a = Settings.ACTION_APPLICATION_SETTINGS; break;
      case "accessibility": a = Settings.ACTION_ACCESSIBILITY_SETTINGS; break;
      case "notifications": a = Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS; break;
      default: a = Settings.ACTION_SETTINGS;
    }
    go(new Intent(a), c);
  }

  @PluginMethod
  public void playSpotify(PluginCall c) {
    Intent i = new Intent(MediaStore.INTENT_ACTION_MEDIA_PLAY_FROM_SEARCH);
    i.setPackage("com.spotify.music");
    i.putExtra(MediaStore.EXTRA_MEDIA_FOCUS, "vnd.android.cursor.item/*");
    i.putExtra(SearchManager.QUERY, c.getString("query", ""));
    go(i, c);
  }

  @PluginMethod
  public void mediaKey(PluginCall c) {
    int k;
    switch (c.getString("key", "")) {
      case "next": k = KeyEvent.KEYCODE_MEDIA_NEXT; break;
      case "previous": k = KeyEvent.KEYCODE_MEDIA_PREVIOUS; break;
      case "pause": k = KeyEvent.KEYCODE_MEDIA_PAUSE; break;
      case "play": k = KeyEvent.KEYCODE_MEDIA_PLAY; break;
      default: k = KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE;
    }
    AudioManager am = (AudioManager) getContext().getSystemService(Context.AUDIO_SERVICE);
    am.dispatchMediaKeyEvent(new KeyEvent(KeyEvent.ACTION_DOWN, k));
    am.dispatchMediaKeyEvent(new KeyEvent(KeyEvent.ACTION_UP, k));
    c.resolve();
  }

  @PluginMethod
  public void addEvent(PluginCall c) {
    Intent i = new Intent(Intent.ACTION_INSERT, CalendarContract.Events.CONTENT_URI);
    i.putExtra(CalendarContract.Events.TITLE, c.getString("title", "Event"));
    i.putExtra(CalendarContract.EXTRA_EVENT_BEGIN_TIME, c.getData().optLong("start"));
    i.putExtra(CalendarContract.EXTRA_EVENT_END_TIME, c.getData().optLong("end"));
    String loc = c.getString("location", "");
    if (!loc.isEmpty()) i.putExtra(CalendarContract.Events.EVENT_LOCATION, loc);
    go(i, c);
  }

  @PluginMethod
  public void a11yStatus(PluginCall c) {
    JSObject o = new JSObject();
    o.put("on", JarvisAccess.inst != null);
    c.resolve(o);
  }

  @PluginMethod
  public void shizukuStatus(PluginCall c) {
    try {
      boolean binder = Shizuku.pingBinder();
      boolean granted = binder && Shizuku.checkSelfPermission() == PackageManager.PERMISSION_GRANTED;
      JSObject o = new JSObject();
      o.put("available", binder);
      o.put("permissionGranted", granted);
      o.put("uid", binder ? Shizuku.getUid() : -1);
      o.put("privilege", !binder ? "offline" : (Shizuku.getUid() == 0 ? "root" : (Shizuku.getUid() == 2000 ? "adb" : "other")));
      c.resolve(o);
    } catch (Exception e) {
      c.reject("Shizuku status unavailable: " + String.valueOf(e.getMessage()));
    }
  }

  @PluginMethod
  public void requestShizukuPermission(final PluginCall c) {
    try {
      if (!Shizuku.pingBinder()) {
        c.reject("Shizuku service is not running. Start Shizuku first.");
        return;
      }
      if (Shizuku.checkSelfPermission() == PackageManager.PERMISSION_GRANTED) {
        JSObject o = new JSObject();
        o.put("granted", true);
        o.put("alreadyGranted", true);
        c.resolve(o);
        return;
      }
      final int requestCode = 2407;
      final Shizuku.OnRequestPermissionResultListener listener = new Shizuku.OnRequestPermissionResultListener() {
        @Override public void onRequestPermissionResult(int code, int result) {
          if (code != requestCode) return;
          Shizuku.removeRequestPermissionResultListener(this);
          JSObject o = new JSObject();
          boolean granted = result == PackageManager.PERMISSION_GRANTED;
          o.put("granted", granted);
          o.put("alreadyGranted", false);
          if (granted) c.resolve(o); else c.reject("Shizuku permission was not granted.");
        }
      };
      Shizuku.addRequestPermissionResultListener(listener);
      Shizuku.requestPermission(requestCode);
    } catch (Exception e) {
      c.reject("Could not request Shizuku permission: " + String.valueOf(e.getMessage()));
    }
  }

  @PluginMethod
  public void capabilities(PluginCall c) {
    try {
      Context ctx = getContext();
      JSObject o = new JSObject();
      o.put("accessibility", JarvisAccess.inst != null);
      o.put("notificationAccess", Settings.Secure.getString(ctx.getContentResolver(), "enabled_notification_listeners") != null &&
        Settings.Secure.getString(ctx.getContentResolver(), "enabled_notification_listeners").contains(ctx.getPackageName()));
      o.put("modifySystemSettings", Settings.System.canWrite(ctx));
      o.put("allFilesAccess", Build.VERSION.SDK_INT >= 30 && Environment.isExternalStorageManager());
      o.put("microphonePermission", ctx.checkSelfPermission(android.Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED);
      o.put("androidVersion", Build.VERSION.RELEASE);
      o.put("sdk", Build.VERSION.SDK_INT);
      o.put("package", ctx.getPackageName());
      boolean shizukuBinder = false;
      boolean shizukuGranted = false;
      try { shizukuBinder = Shizuku.pingBinder(); shizukuGranted = shizukuBinder && Shizuku.checkSelfPermission() == PackageManager.PERMISSION_GRANTED; } catch (Exception ignored) {}
      o.put("shizukuAvailable", shizukuBinder);
      o.put("shizukuPermission", shizukuGranted);
      c.resolve(o);
    } catch (Exception e) { c.reject(String.valueOf(e.getMessage())); }
  }

  @PluginMethod
  public void volumeStatus(PluginCall c) {
    try {
      AudioManager am = (AudioManager) getContext().getSystemService(Context.AUDIO_SERVICE);
      int current = am.getStreamVolume(AudioManager.STREAM_MUSIC);
      int max = am.getStreamMaxVolume(AudioManager.STREAM_MUSIC);
      JSObject o = new JSObject();
      o.put("current", current);
      o.put("max", max);
      o.put("percent", max > 0 ? Math.round(current * 100f / max) : 0);
      o.put("muted", current == 0);
      c.resolve(o);
    } catch (Exception e) { c.reject(String.valueOf(e.getMessage())); }
  }

  @PluginMethod
  public void armTask(PluginCall c) {
    JarvisAccess.arm(c.getString("task", ""), c.getString("arg", ""), c.getData().optLong("ttl", 20000));
    c.resolve();
  }

  @PluginMethod
  public void shareText(PluginCall c) {
    Intent s = new Intent(Intent.ACTION_SEND);
    s.setType("text/plain");
    s.putExtra(Intent.EXTRA_TEXT, c.getString("text", ""));
    go(Intent.createChooser(s, "Share"), c);
  }

  @PluginMethod
  public void torch(PluginCall c) {
    try {
      CameraManager cm = (CameraManager) getContext().getSystemService(Context.CAMERA_SERVICE);
      for (String id : cm.getCameraIdList()) {
        Boolean f = cm.getCameraCharacteristics(id).get(CameraCharacteristics.FLASH_INFO_AVAILABLE);
        if (f != null && f) {
          cm.setTorchMode(id, c.getBoolean("on", true));
          c.resolve();
          return;
        }
      }
      c.reject("No flashlight found");
    } catch (Exception e) {
      c.reject(String.valueOf(e.getMessage()));
    }
  }

  @PluginMethod
  public void volume(PluginCall c) {
    AudioManager am = (AudioManager) getContext().getSystemService(Context.AUDIO_SERVICE);
    int max = am.getStreamMaxVolume(AudioManager.STREAM_MUSIC);
    int pct = Math.max(0, Math.min(100, c.getInt("percent", 50)));
    am.setStreamVolume(AudioManager.STREAM_MUSIC, Math.round(max * pct / 100f), AudioManager.FLAG_SHOW_UI);
    c.resolve();
  }

  @PluginMethod
  public void setBrightness(PluginCall c) {
    int percent = Math.max(0, Math.min(100, c.getInt("percent", 50)));
    if (!Settings.System.canWrite(getContext())) {
      try {
        Intent i = new Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS, Uri.parse("package:" + getContext().getPackageName()));
        i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        getContext().startActivity(i);
        JSObject result = new JSObject();
        result.put("permissionRequired", true);
        c.resolve(result);
      } catch (Exception e) { c.reject(String.valueOf(e.getMessage())); }
      return;
    }
    try {
      Settings.System.putInt(getContext().getContentResolver(), Settings.System.SCREEN_BRIGHTNESS_MODE, Settings.System.SCREEN_BRIGHTNESS_MODE_MANUAL);
      boolean ok = Settings.System.putInt(getContext().getContentResolver(), Settings.System.SCREEN_BRIGHTNESS, Math.round(percent * 255f / 100f));
      if (ok) c.resolve(); else c.reject("Android did not accept the brightness setting");
    } catch (Exception e) { c.reject(String.valueOf(e.getMessage())); }
  }

  @PluginMethod
  public void brightnessStatus(PluginCall c) {
    try {
      int value = Settings.System.getInt(getContext().getContentResolver(), Settings.System.SCREEN_BRIGHTNESS, 128);
      int mode = Settings.System.getInt(getContext().getContentResolver(), Settings.System.SCREEN_BRIGHTNESS_MODE, Settings.System.SCREEN_BRIGHTNESS_MODE_MANUAL);
      JSObject o = new JSObject();
      o.put("percent", Math.round(value * 100f / 255f));
      o.put("automatic", mode == Settings.System.SCREEN_BRIGHTNESS_MODE_AUTOMATIC);
      o.put("canWrite", Settings.System.canWrite(getContext()));
      c.resolve(o);
    } catch (Exception e) { c.reject(String.valueOf(e.getMessage())); }
  }

  @PluginMethod
  public void setAlarm(PluginCall c) {
    int h = c.getInt("hour", 0);
    int m = c.getInt("minute", 0);
    Intent i = new Intent(AlarmClock.ACTION_SET_ALARM);
    i.putExtra(AlarmClock.EXTRA_HOUR, h);
    i.putExtra(AlarmClock.EXTRA_MINUTES, m);
    i.putExtra(AlarmClock.EXTRA_MESSAGE, c.getString("label", "Reminder"));
    i.putExtra(AlarmClock.EXTRA_SKIP_UI, true);
    go(i, c);
  }

  @PluginMethod
  public void setTimer(PluginCall c) {
    int sec = c.getInt("seconds", 60);
    Intent i = new Intent(AlarmClock.ACTION_SET_TIMER);
    i.putExtra(AlarmClock.EXTRA_LENGTH, sec);
    i.putExtra(AlarmClock.EXTRA_MESSAGE, c.getString("label", "Timer"));
    i.putExtra(AlarmClock.EXTRA_SKIP_UI, true);
    go(i, c);
  }

  @PluginMethod
  public void consumeAssist(PluginCall c) {
    JSObject o = new JSObject();
    boolean pop = getActivity() instanceof PopupActivity;
    o.put("v", pop && assist);
    if (pop) assist = false;
    c.resolve(o);
  }

  @PluginMethod
  public void isPopup(PluginCall c) {
    JSObject o = new JSObject();
    o.put("v", getActivity() instanceof PopupActivity);
    c.resolve(o);
  }

  @PluginMethod
  public void closePopup(PluginCall c) {
    if (getActivity() instanceof PopupActivity) getActivity().finish();
    c.resolve();
  }

  @PluginMethod
  public void openMain(PluginCall c) {
    Intent i = new Intent(getContext(), MainActivity.class);
    i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_REORDER_TO_FRONT | Intent.FLAG_ACTIVITY_SINGLE_TOP);
    getContext().startActivity(i);
    if (getActivity() instanceof PopupActivity) getActivity().finish();
    c.resolve();
  }

  @PluginMethod
  public void spotifyBg(final PluginCall c) {
    try {
      MediaSessionManager sm = (MediaSessionManager) getContext().getSystemService(Context.MEDIA_SESSION_SERVICE);
      List<MediaController> list = sm.getActiveSessions(new ComponentName(getContext(), JarvisNotif.class));
      MediaController found = null;
      for (MediaController x : list) {
        if ("com.spotify.music".equals(x.getPackageName())) found = x;
      }
      if (found == null) {
        c.reject("no spotify session");
        return;
      }
      final MediaController sp = found;
      PlaybackState ps0 = sp.getPlaybackState();
      final boolean was = ps0 != null && ps0.getState() == PlaybackState.STATE_PLAYING;
      MediaMetadata md0 = sp.getMetadata();
      final String t0 = md0 == null ? "" : String.valueOf(md0.getString(MediaMetadata.METADATA_KEY_TITLE));
      sp.getTransportControls().playFromSearch(c.getString("query", ""), new Bundle());
      new Handler(Looper.getMainLooper()).postDelayed(new Runnable() {
        public void run() {
          PlaybackState ps = sp.getPlaybackState();
          MediaMetadata md = sp.getMetadata();
          String t1 = md == null ? "" : String.valueOf(md.getString(MediaMetadata.METADATA_KEY_TITLE));
          boolean playing = ps != null && ps.getState() == PlaybackState.STATE_PLAYING;
          JSObject o = new JSObject();
          o.put("playing", playing && (!was || !t0.equals(t1)));
          o.put("title", t1);
          c.resolve(o);
        }
      }, 3000);
    } catch (SecurityException e) {
      c.reject("no notification access");
    } catch (Exception e) {
      c.reject(String.valueOf(e.getMessage()));
    }
  }

  @PluginMethod
  public void status(PluginCall c) {
    try {
      JSObject o = new JSObject();
      Intent b = getContext().registerReceiver(null, new IntentFilter(Intent.ACTION_BATTERY_CHANGED));
      if (b != null) {
        int lv = b.getIntExtra(BatteryManager.EXTRA_LEVEL, -1);
        int sc = b.getIntExtra(BatteryManager.EXTRA_SCALE, 100);
        int st = b.getIntExtra(BatteryManager.EXTRA_STATUS, -1);
        o.put("battery", lv * 100 / Math.max(sc, 1));
        o.put("charging", st == BatteryManager.BATTERY_STATUS_CHARGING || st == BatteryManager.BATTERY_STATUS_FULL);
        o.put("tempC", b.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0) / 10.0);
      }
      ConnectivityManager cm = (ConnectivityManager) getContext().getSystemService(Context.CONNECTIVITY_SERVICE);
      String net = "none";
      int down = 0;
      Network n = cm.getActiveNetwork();
      if (n != null) {
        NetworkCapabilities nc = cm.getNetworkCapabilities(n);
        if (nc != null) {
          if (nc.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) net = "wifi";
          else if (nc.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR)) net = "cellular";
          else net = "other";
          down = nc.getLinkDownstreamBandwidthKbps();
        }
      }
      o.put("network", net);
      o.put("downKbps", down);
      ActivityManager am = (ActivityManager) getContext().getSystemService(Context.ACTIVITY_SERVICE);
      ActivityManager.MemoryInfo mi = new ActivityManager.MemoryInfo();
      am.getMemoryInfo(mi);
      o.put("ramFreeMB", mi.availMem / 1048576L);
      o.put("ramTotalMB", mi.totalMem / 1048576L);
      StatFs sf = new StatFs(Environment.getDataDirectory().getPath());
      o.put("storageFreeGB", sf.getAvailableBytes() / 1073741824.0);
      o.put("storageTotalGB", sf.getTotalBytes() / 1073741824.0);
      c.resolve(o);
    } catch (Exception e) {
      c.reject(String.valueOf(e.getMessage()));
    }
  }

  @PluginMethod
  public void clipSet(PluginCall c) {
    ClipboardManager cm = (ClipboardManager) getContext().getSystemService(Context.CLIPBOARD_SERVICE);
    cm.setPrimaryClip(ClipData.newPlainText("Jarvis", c.getString("text", "")));
    c.resolve();
  }

  @PluginMethod
  public void clipGet(PluginCall c) {
    ClipboardManager cm = (ClipboardManager) getContext().getSystemService(Context.CLIPBOARD_SERVICE);
    String t = "";
    ClipData d = cm.getPrimaryClip();
    if (d != null && d.getItemCount() > 0) {
      CharSequence s = d.getItemAt(0).coerceToText(getContext());
      if (s != null) t = s.toString();
    }
    JSObject o = new JSObject();
    o.put("text", t);
    c.resolve(o);
  }

  @PluginMethod
  public void notifs(PluginCall c) {
    JarvisNotif s = JarvisNotif.inst;
    if (s == null) {
      c.reject("listener off");
      return;
    }
    try {
      JSArray arr = new JSArray();
      int count = 0;
      for (StatusBarNotification sbn : s.getActiveNotifications()) {
        if (count >= 20) break;
        Bundle ex = sbn.getNotification().extras;
        CharSequence t = ex.getCharSequence(Notification.EXTRA_TITLE);
        CharSequence x = ex.getCharSequence(Notification.EXTRA_TEXT);
        if (t == null && x == null) continue;
        arr.put(sbn.getPackageName() + ": " + t + " - " + x);
        count++;
      }
      JSObject o = new JSObject();
      o.put("list", arr);
      c.resolve(o);
    } catch (Exception e) {
      c.reject(String.valueOf(e.getMessage()));
    }
  }

  @PluginMethod
  public void clearNotifs(PluginCall c) {
    JarvisNotif s = JarvisNotif.inst;
    if (s == null) {
      c.reject("listener off");
      return;
    }
    s.cancelAllNotifications();
    c.resolve();
  }

  private JSObject enc(Bitmap src) {
    Bitmap bmp = src.copy(Bitmap.Config.ARGB_8888, false);
    int w = bmp.getWidth();
    int h = bmp.getHeight();
    float k = Math.min(1f, 1024f / Math.max(w, h));
    Bitmap sm = Bitmap.createScaledBitmap(bmp, Math.max(1, Math.round(w * k)), Math.max(1, Math.round(h * k)), true);
    ByteArrayOutputStream bo = new ByteArrayOutputStream();
    sm.compress(Bitmap.CompressFormat.JPEG, 70, bo);
    JSObject o = new JSObject();
    o.put("b64", Base64.encodeToString(bo.toByteArray(), Base64.NO_WRAP));
    return o;
  }

  @PluginMethod
  public void screenshot(final PluginCall c) {
    try {
      Bitmap b = JarvisSession.shot;
      if (b != null && System.currentTimeMillis() - JarvisSession.shotAt < 120000) {
        c.resolve(enc(b));
        return;
      }
      final JarvisAccess s = JarvisAccess.inst;
      if (s == null) {
        c.reject("Accessibility is off");
        return;
      }
      if (Build.VERSION.SDK_INT < 30) {
        c.reject("Needs Android 11 or newer");
        return;
      }
      s.takeScreenshot(Display.DEFAULT_DISPLAY, getContext().getMainExecutor(), new AccessibilityService.TakeScreenshotCallback() {
        @Override
        public void onSuccess(AccessibilityService.ScreenshotResult r) {
          try {
            Bitmap hw = Bitmap.wrapHardwareBuffer(r.getHardwareBuffer(), r.getColorSpace());
            c.resolve(enc(hw));
          } catch (Exception e) {
            c.reject(String.valueOf(e.getMessage()));
          }
        }

        @Override
        public void onFailure(int code) {
          c.reject("Screenshot failed, code " + code);
        }
      });
    } catch (Exception e) {
      c.reject(String.valueOf(e.getMessage()));
    }
  }

  private JarvisAccess acc(PluginCall c) {
    JarvisAccess s = JarvisAccess.inst;
    if (s == null) c.reject("Accessibility is off");
    return s;
  }

  @PluginMethod
  public void readScreen(PluginCall c) {
    JarvisAccess s = acc(c);
    if (s == null) return;
    JSObject o = new JSObject();
    o.put("text", s.readScreen());
    c.resolve(o);
  }

  @PluginMethod
  public void globalAction(PluginCall c) {
    JarvisAccess s = acc(c);
    if (s == null) return;
    if (s.doGlobal(c.getString("action", ""))) c.resolve();
    else c.reject("Action not supported");
  }

  @PluginMethod
  public void tapText(PluginCall c) {
    JarvisAccess s = acc(c);
    if (s == null) return;
    if (s.tapByText(c.getString("text", ""))) c.resolve();
    else c.reject("No matching element on screen");
  }

  @PluginMethod
  public void typeText(PluginCall c) {
    JarvisAccess s = acc(c);
    if (s == null) return;
    if (s.typeInto(c.getString("text", ""))) c.resolve();
    else c.reject("No focused non-password text field");
  }

  @PluginMethod
  public void longClickText(PluginCall c) {
    JarvisAccess s = acc(c);
    if (s == null) return;
    if (s.longClickByText(c.getString("text", ""))) c.resolve();
    else c.reject("No long-clickable matching element");
  }

  @PluginMethod
  public void scrollScreen(PluginCall c) {
    JarvisAccess s = acc(c);
    if (s == null) return;
    if (s.scroll(c.getString("direction", "down"))) c.resolve();
    else c.reject("No scrollable element found");
  }

  @PluginMethod
  public void tapPoint(PluginCall c) {
    JarvisAccess s = acc(c);
    if (s == null) return;
    float x = (float) c.getData().optDouble("x", -1d);
    float y = (float) c.getData().optDouble("y", -1d);
    if (x < 0 || y < 0) { c.reject("Coordinates must be non-negative"); return; }
    if (s.tapPoint(x, y, c.getData().optBoolean("longPress", false))) c.resolve();
    else c.reject("Gesture could not be dispatched");
  }

  @PluginMethod
  public void screenTree(PluginCall c) {
    JarvisAccess s = acc(c);
    if (s == null) return;
    JSObject o = new JSObject();
    o.put("tree", s.screenTree());
    c.resolve(o);
  }

  @PluginMethod
  public void listApps(PluginCall c) {
    try {
      PackageManager pm = getContext().getPackageManager();
      Intent q = new Intent(Intent.ACTION_MAIN);
      q.addCategory(Intent.CATEGORY_LAUNCHER);
      JSArray arr = new JSArray();
      for (ResolveInfo ri : pm.queryIntentActivities(q, 0)) {
        JSObject o = new JSObject();
        o.put("label", String.valueOf(ri.loadLabel(pm)));
        o.put("pkg", ri.activityInfo.packageName);
        arr.put(o);
      }
      JSObject r = new JSObject();
      r.put("apps", arr);
      c.resolve(r);
    } catch (Exception e) {
      c.reject(String.valueOf(e.getMessage()));
    }
  }

  @PluginMethod
  public void launchApp(PluginCall c) {
    Intent i = getContext().getPackageManager().getLaunchIntentForPackage(c.getString("pkg", ""));
    if (i == null) {
      c.reject("App not found");
      return;
    }
    go(i, c);
  }

  private File fp(String p) throws Exception {
    File root = Environment.getExternalStorageDirectory();
    File f = (p == null || p.isEmpty() || p.equals("/")) ? root : (p.startsWith("/") ? new File(p) : new File(root, p));
    String rootPath = root.getCanonicalPath();
    String filePath = f.getCanonicalPath();
    if (!filePath.equals(rootPath) && !filePath.startsWith(rootPath + File.separator)) throw new Exception("Path is outside shared storage");
    return f;
  }

  @PluginMethod
  public void fsStatus(PluginCall c) {
    JSObject o = new JSObject();
    o.put("ok", Build.VERSION.SDK_INT < 30 || Environment.isExternalStorageManager());
    c.resolve(o);
  }

  @PluginMethod
  public void openFilesAccess(PluginCall c) {
    go(new Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION, Uri.parse("package:" + getContext().getPackageName())), c);
  }

  @PluginMethod
  public void fsList(PluginCall c) {
    try {
      File[] fs = fp(c.getString("path", "")).listFiles();
      JSArray arr = new JSArray();
      if (fs != null) {
        Arrays.sort(fs);
        int n = 0;
        for (File f : fs) {
          if (n++ >= 80) break;
          JSObject o = new JSObject();
          o.put("name", f.getName());
          o.put("dir", f.isDirectory());
          o.put("size", f.length());
          arr.put(o);
        }
      }
      JSObject r = new JSObject();
      r.put("items", arr);
      c.resolve(r);
    } catch (Exception e) {
      c.reject(String.valueOf(e.getMessage()));
    }
  }

  @PluginMethod
  public void fsRead(PluginCall c) {
    try {
      File f = fp(c.getString("path", ""));
      int max = c.getInt("max", 12000);
      byte[] buf = new byte[(int) Math.min(f.length(), (long) max * 3)];
      FileInputStream in = new FileInputStream(f);
      int len = in.read(buf);
      in.close();
      String t = new String(buf, 0, Math.max(len, 0), "UTF-8");
      if (t.length() > max) t = t.substring(0, max);
      JSObject o = new JSObject();
      o.put("text", t);
      c.resolve(o);
    } catch (Exception e) {
      c.reject(String.valueOf(e.getMessage()));
    }
  }

  @PluginMethod
  public void fsReadB64(PluginCall c) {
    try {
      File f = fp(c.getString("path", ""));
      if (f.length() > 15L * 1024 * 1024) throw new Exception("File is larger than 15 MB");
      byte[] b = new byte[(int) f.length()];
      FileInputStream in = new FileInputStream(f);
      int off = 0;
      while (off < b.length) {
        int r = in.read(b, off, b.length - off);
        if (r < 0) break;
        off += r;
      }
      in.close();
      JSObject o = new JSObject();
      o.put("b64", Base64.encodeToString(b, Base64.NO_WRAP));
      c.resolve(o);
    } catch (Exception e) {
      c.reject(String.valueOf(e.getMessage()));
    }
  }

  private void walk(File d, String q, int depth, JSArray out) {
    if (depth > 5 || out.length() >= 30) return;
    File[] fs = d.listFiles();
    if (fs == null) return;
    for (File f : fs) {
      if (out.length() >= 30) return;
      if (f.getName().toLowerCase().contains(q)) out.put(f.getAbsolutePath());
      if (f.isDirectory() && !f.getName().startsWith(".") && !f.getName().equals("Android")) walk(f, q, depth + 1, out);
    }
  }

  @PluginMethod
  public void fsSearch(PluginCall c) {
    try {
      JSArray arr = new JSArray();
      walk(fp(c.getString("path", "")), c.getString("query", "").toLowerCase(), 0, arr);
      JSObject r = new JSObject();
      r.put("list", arr);
      c.resolve(r);
    } catch (Exception e) {
      c.reject(String.valueOf(e.getMessage()));
    }
  }

  @PluginMethod
  public void fsWrite(PluginCall c) {
    try {
      File f = fp(c.getString("path", ""));
      boolean app = c.getBoolean("append", false);
      if (f.exists() && !app) throw new Exception("File already exists; append or pick another name");
      File par = f.getParentFile();
      if (par != null) par.mkdirs();
      FileOutputStream os = new FileOutputStream(f, app);
      os.write(c.getString("text", "").getBytes("UTF-8"));
      os.close();
      c.resolve();
    } catch (Exception e) {
      c.reject(String.valueOf(e.getMessage()));
    }
  }

  @PluginMethod
  public void fsMove(PluginCall c) {
    try {
      File a = fp(c.getString("from", ""));
      File b = fp(c.getString("to", ""));
      if (b.exists()) throw new Exception("Destination already exists");
      File par = b.getParentFile();
      if (par != null) par.mkdirs();
      if (!a.renameTo(b)) throw new Exception("Move failed");
      c.resolve();
    } catch (Exception e) {
      c.reject(String.valueOf(e.getMessage()));
    }
  }

  @PluginMethod
  public void fsDelete(PluginCall c) {
    try {
      File f = fp(c.getString("path", ""));
      if (f.getCanonicalPath().equals(Environment.getExternalStorageDirectory().getCanonicalPath())) throw new Exception("Refusing to delete the storage root");
      String[] kids = f.list();
      if (f.isDirectory() && kids != null && kids.length > 0) throw new Exception("Folder is not empty");
      if (!f.delete()) throw new Exception("Delete failed");
      c.resolve();
    } catch (Exception e) {
      c.reject(String.valueOf(e.getMessage()));
    }
  }

  @PluginMethod
  public void consumeUrl(PluginCall c) {
    JSObject o = new JSObject();
    o.put("url", pendingUrl == null ? "" : pendingUrl);
    pendingUrl = null;
    c.resolve(o);
  }

  @PluginMethod
  public void scheduleReminder(PluginCall c) {
    try {
      String id = c.getString("id", String.valueOf(System.currentTimeMillis()));
      long at = c.getData().optLong("at");
      String title = c.getString("title", "");
      String text = c.getString("text", "");
      String audio = c.getString("audio", "");
      if (at <= System.currentTimeMillis()) throw new Exception("Time is in the past");
      if (!audio.isEmpty()) {
        FileOutputStream os = new FileOutputStream(new File(getContext().getFilesDir(), "rem_" + id + ".mp3"));
        os.write(Base64.decode(audio, Base64.DEFAULT));
        os.close();
      }
      Reminders.add(getContext(), id, at, title, text);
      Reminders.arm(getContext(), id, at, title, text);
      c.resolve();
    } catch (Exception e) {
      c.reject(String.valueOf(e.getMessage()));
    }
  }

  @PluginMethod
  public void cancelReminder(PluginCall c) {
    try {
      Reminders.cancel(getContext(), c.getString("id", ""));
      c.resolve();
    } catch (Exception e) {
      c.reject(String.valueOf(e.getMessage()));
    }
  }

  @PluginMethod
  public void requestNotifPermission(PluginCall c) {
    if (Build.VERSION.SDK_INT >= 33) {
      ActivityCompat.requestPermissions(getActivity(), new String[] { "android.permission.POST_NOTIFICATIONS" }, 7);
    }
    c.resolve();
  }
}
EOF
cat > $D/PopupActivity.java <<'EOF'
package com.stark.jarvis;

import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.os.Bundle;
import android.util.DisplayMetrics;
import android.view.WindowManager;
import android.view.Gravity;
import android.view.ViewGroup;
import com.getcapacitor.BridgeActivity;

public class PopupActivity extends BridgeActivity {
  @Override
  public void onCreate(Bundle savedInstanceState) {
    registerPlugin(JarvisNative.class);
    DisplayMetrics dm = getResources().getDisplayMetrics();
    getWindow().setLayout(ViewGroup.LayoutParams.MATCH_PARENT, (int) (dm.heightPixels * 0.72f));
    getWindow().setGravity(Gravity.BOTTOM);
    super.onCreate(savedInstanceState);
    setFinishOnTouchOutside(true);
    clear();
  }

  @Override
  public void onResume() {
    super.onResume();
    clear();
  }

  private void clear() {
    try {
      getWindow().setBackgroundDrawable(new ColorDrawable(Color.TRANSPARENT));
      getWindow().clearFlags(WindowManager.LayoutParams.FLAG_DIM_BEHIND);
      getWindow().getDecorView().setBackgroundColor(Color.TRANSPARENT);
    } catch (Exception e) { }
    try {
      getBridge().getWebView().setBackgroundColor(Color.TRANSPARENT);
    } catch (Exception e) { }
  }
}
EOF
cat > $D/Reminders.java <<'EOF'
package com.stark.jarvis;

import android.app.AlarmManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import java.io.File;
import org.json.JSONArray;
import org.json.JSONObject;

public class Reminders {
  static final String PREF = "jarvis_rem";

  static JSONArray load(Context c) {
    try {
      return new JSONArray(c.getSharedPreferences(PREF, 0).getString("list", "[]"));
    } catch (Exception e) {
      return new JSONArray();
    }
  }

  static void save(Context c, JSONArray a) {
    c.getSharedPreferences(PREF, 0).edit().putString("list", a.toString()).apply();
  }

  static JSONArray without(Context c, String id) throws Exception {
    JSONArray a = load(c);
    JSONArray n = new JSONArray();
    for (int i = 0; i < a.length(); i++) {
      if (!a.getJSONObject(i).getString("id").equals(id)) n.put(a.getJSONObject(i));
    }
    return n;
  }

  static void add(Context c, String id, long at, String title, String text) throws Exception {
    JSONArray n = without(c, id);
    JSONObject o = new JSONObject();
    o.put("id", id);
    o.put("at", at);
    o.put("title", title);
    o.put("text", text);
    n.put(o);
    save(c, n);
  }

  static void remove(Context c, String id) {
    try {
      save(c, without(c, id));
    } catch (Exception e) { }
  }

  static PendingIntent pi(Context c, String id, String title, String text) {
    Intent i = new Intent(c, ReminderReceiver.class);
    i.putExtra("id", id);
    i.putExtra("title", title);
    i.putExtra("text", text);
    return PendingIntent.getBroadcast(c, id.hashCode(), i, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
  }

  static void arm(Context c, String id, long at, String title, String text) {
    AlarmManager am = (AlarmManager) c.getSystemService(Context.ALARM_SERVICE);
    Intent open = c.getPackageManager().getLaunchIntentForPackage(c.getPackageName());
    PendingIntent show = PendingIntent.getActivity(c, 1, open != null ? open : new Intent(), PendingIntent.FLAG_IMMUTABLE);
    am.setAlarmClock(new AlarmManager.AlarmClockInfo(at, show), pi(c, id, title, text));
  }

  static void cancel(Context c, String id) {
    AlarmManager am = (AlarmManager) c.getSystemService(Context.ALARM_SERVICE);
    am.cancel(pi(c, id, "", ""));
    remove(c, id);
    new File(c.getFilesDir(), "rem_" + id + ".mp3").delete();
  }

  static void rearm(Context c) {
    try {
      JSONArray a = load(c);
      long now = System.currentTimeMillis();
      for (int i = 0; i < a.length(); i++) {
        JSONObject o = a.getJSONObject(i);
        if (o.getLong("at") > now) arm(c, o.getString("id"), o.getLong("at"), o.optString("title"), o.optString("text"));
      }
    } catch (Exception e) { }
  }
}
EOF
cat > $D/BootReceiver.java <<'EOF'
package com.stark.jarvis;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

public class BootReceiver extends BroadcastReceiver {
  @Override
  public void onReceive(Context context, Intent intent) {
    Reminders.rearm(context);
  }
}
EOF
cat > $D/ReminderReceiver.java <<'EOF'
package com.stark.jarvis;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.media.AudioAttributes;
import android.media.MediaPlayer;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.os.PowerManager;
import android.speech.tts.TextToSpeech;
import android.speech.tts.UtteranceProgressListener;
import java.io.File;
import java.util.concurrent.atomic.AtomicBoolean;

public class ReminderReceiver extends BroadcastReceiver {
  @Override
  public void onReceive(final Context ctx, Intent in) {
    final PendingResult pr = goAsync();
    final String id = in.getStringExtra("id");
    final String title = in.getStringExtra("title");
    final String text = in.getStringExtra("text");
    Reminders.remove(ctx, id);
    PowerManager pm = (PowerManager) ctx.getSystemService(Context.POWER_SERVICE);
    final PowerManager.WakeLock wl = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "jarvis:reminder");
    wl.acquire(20000);
    notifyUser(ctx, title, text);
    final File f = new File(ctx.getFilesDir(), "rem_" + id + ".mp3");
    final AtomicBoolean fin = new AtomicBoolean(false);
    final Runnable done = new Runnable() {
      public void run() {
        if (!fin.compareAndSet(false, true)) return;
        try { f.delete(); } catch (Exception e) { }
        try { if (wl.isHeld()) wl.release(); } catch (Exception e) { }
        pr.finish();
      }
    };
    new Handler(Looper.getMainLooper()).postDelayed(done, 9000);
    if (f.exists()) {
      try {
        final MediaPlayer mp = new MediaPlayer();
        mp.setAudioAttributes(new AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ALARM).setContentType(AudioAttributes.CONTENT_TYPE_SPEECH).build());
        mp.setDataSource(f.getAbsolutePath());
        mp.setOnCompletionListener(new MediaPlayer.OnCompletionListener() {
          public void onCompletion(MediaPlayer m) {
            m.release();
            done.run();
          }
        });
        mp.setOnErrorListener(new MediaPlayer.OnErrorListener() {
          public boolean onError(MediaPlayer m, int what, int extra) {
            m.release();
            speak(ctx, text, done);
            return true;
          }
        });
        mp.prepare();
        mp.start();
        return;
      } catch (Exception e) { }
    }
    speak(ctx, text, done);
  }

  private void speak(Context ctx, final String text, final Runnable done) {
    try {
      final TextToSpeech[] h = new TextToSpeech[1];
      h[0] = new TextToSpeech(ctx.getApplicationContext(), new TextToSpeech.OnInitListener() {
        public void onInit(int status) {
          if (status != TextToSpeech.SUCCESS || h[0] == null) {
            done.run();
            return;
          }
          h[0].setOnUtteranceProgressListener(new UtteranceProgressListener() {
            public void onStart(String u) { }
            public void onDone(String u) { h[0].shutdown(); done.run(); }
            public void onError(String u) { h[0].shutdown(); done.run(); }
          });
          h[0].speak(text, TextToSpeech.QUEUE_FLUSH, null, "rem");
        }
      });
    } catch (Exception e) {
      done.run();
    }
  }

  private void notifyUser(Context ctx, String title, String text) {
    try {
      NotificationManager nm = (NotificationManager) ctx.getSystemService(Context.NOTIFICATION_SERVICE);
      Notification.Builder b;
      if (Build.VERSION.SDK_INT >= 26) {
        nm.createNotificationChannel(new NotificationChannel("jarvis_rem", "Jarvis reminders", NotificationManager.IMPORTANCE_HIGH));
        b = new Notification.Builder(ctx, "jarvis_rem");
      } else {
        b = new Notification.Builder(ctx);
      }
      b.setContentTitle("Jarvis").setContentText(title == null || title.isEmpty() ? text : title).setSmallIcon(android.R.drawable.ic_popup_reminder).setAutoCancel(true);
      Intent open = ctx.getPackageManager().getLaunchIntentForPackage(ctx.getPackageName());
      if (open != null) b.setContentIntent(PendingIntent.getActivity(ctx, 0, open, PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT));
      nm.notify((int) (System.currentTimeMillis() & 0x7fffffff), b.build());
    } catch (Exception e) { }
  }
}
EOF
cat > $D/JarvisVoiceService.java <<'EOF'
package com.stark.jarvis;

import android.service.voice.VoiceInteractionService;

public class JarvisVoiceService extends VoiceInteractionService {
}
EOF
cat > $D/JarvisSessionService.java <<'EOF'
package com.stark.jarvis;

import android.os.Bundle;
import android.service.voice.VoiceInteractionSession;
import android.service.voice.VoiceInteractionSessionService;

public class JarvisSessionService extends VoiceInteractionSessionService {
  @Override
  public VoiceInteractionSession onNewSession(Bundle args) {
    return new JarvisSession(this);
  }
}
EOF
cat > $D/JarvisSession.java <<'EOF'
package com.stark.jarvis;

import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.graphics.Bitmap;
import android.os.Handler;
import android.os.Looper;
import android.service.voice.VoiceInteractionSession;

public class JarvisSession extends VoiceInteractionSession {
  static volatile Bitmap shot;
  static volatile long shotAt = 0;

  @Override
  public void onHandleScreenshot(Bitmap screenshot) {
    if (screenshot != null) {
      shot = screenshot;
      shotAt = System.currentTimeMillis();
    }
  }

  public JarvisSession(Context context) {
    super(context);
  }

  @Override
  public void onShow(Bundle args, int flags) {
    super.onShow(args, flags);
    Intent i = new Intent(getContext(), AssistActivity.class);
    try {
      startAssistantActivity(i);
    } catch (Exception e) {
      try {
        i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        getContext().startActivity(i);
      } catch (Exception e2) { }
    }
    new Handler(Looper.getMainLooper()).postDelayed(new Runnable() { public void run() { hide(); } }, 4000);
  }
}
EOF
cat > $D/AssistActivity.java <<'EOF'
package com.stark.jarvis;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;

public class AssistActivity extends Activity {
  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    JarvisNative.assist = true;
    try {
      Intent i = new Intent(this, PopupActivity.class);
      i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_REORDER_TO_FRONT | Intent.FLAG_ACTIVITY_SINGLE_TOP);
      startActivity(i);
    } catch (Exception e) {
      Intent m = new Intent(this, MainActivity.class);
      m.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
      startActivity(m);
    }
    finish();
  }
}
EOF
cat > $D/JarvisRecognition.java <<'EOF'
package com.stark.jarvis;

import android.content.Intent;
import android.speech.RecognitionService;
import android.speech.SpeechRecognizer;

public class JarvisRecognition extends RecognitionService {
  @Override
  protected void onStartListening(Intent intent, Callback callback) {
    try {
      callback.error(SpeechRecognizer.ERROR_CLIENT);
    } catch (Exception e) { }
  }

  @Override
  protected void onCancel(Callback callback) { }

  @Override
  protected void onStopListening(Callback callback) { }
}
EOF
cat > $D/JarvisNotif.java <<'EOF'
package com.stark.jarvis;

import android.service.notification.NotificationListenerService;

public class JarvisNotif extends NotificationListenerService {
  static volatile JarvisNotif inst;

  @Override
  public void onListenerConnected() {
    inst = this;
  }

  @Override
  public void onListenerDisconnected() {
    inst = null;
  }
}
EOF
npx cap sync android
cd android
chmod +x gradlew
./gradlew assembleDebug
