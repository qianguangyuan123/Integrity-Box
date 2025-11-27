const MODDIR = `/data/adb/modules/playintegrity/webroot/common_scripts`;
const PROP = `/data/adb/modules/playintegrity/module.prop`;

const modalBackdrop = document.getElementById("modal-backdrop");
const modalTitle = document.getElementById("modal-title");
const modalOutput = document.getElementById("modal-output");
const modalClose = document.getElementById("modal-close");

const btns = Array.from(document.querySelectorAll(".btn"));

/* Toast messages */
const messageMap = {
  "kill.sh":       { success: "Process Killed Successfully", type: "info" },
  "user.sh":       { start: "Blacklist Unnecessary Apps", type: "info" },
  "stop":       { success: "Switched to Blacklist Mode", type: "info" },
  "start":      { success: "Switched to Whitelist Mode", type: "info" },
  "spoof.sh":      { success: "Applied", type: "info" },
  "resetprop.sh":  { success: "Done, Reopen detector to check", type: "info" },
  "piffork":       { start: "All changes will be applied immediately", type: "info" },
  "pif.sh":        { success: "Done!", type: "info" },
  "vending":       { start: "Let's Go 😋", type: "info" },
  "patch.sh":      { success: "Patch Status : ✅ Spoofed", type: "info" },
  "key.sh":        { success: "Keybox has been updated✅", type: "info" },
  "app.sh":        { start: " ", success: "Detection Complete", type: "info" },
  "support":       { start: "Become a Supporter", type: "info" },
  "boot_hash":     { start: "Paste your boot hash buddy", success: "Boot hash operation complete", type: "success" }
};

/* KernelSU toast */
function popup(msg, type="info") {
  try {
    if (typeof window.toast === "function") { window.toast(String(msg)); return; }
    if (window.kernelsu && typeof window.kernelsu.toast === "function") { window.kernelsu.toast(String(msg)); return; }
    if (typeof ksu === "object" && typeof ksu.toast === "function") { ksu.toast(String(msg)); return; }
  } catch {}

  // fallback DOM popup
  const n = document.createElement("div");
  n.className = "webui-popup";
  n.textContent = msg;
  const colors = { error:"#f44336", success:"#4caf50", info:"#1565c0", warn:"#ff8f00" };
  const bg = colors[type] || "#0099FF";
  Object.assign(n.style, {
    position:"fixed",top:"-70px",left:"50%",transform:"translateX(-50%)",
    background:bg,color:"#fff",padding:"0.8rem 1.2rem",borderRadius:"8px",
    boxShadow:"0 6px 18px rgba(0,0,0,0.35)",fontWeight:"600",zIndex:"99999",
    transition:"top 0.36s,opacity 0.36s",opacity:"0"
  });
  document.body.appendChild(n);
  requestAnimationFrame(()=>{ n.style.top="20px"; n.style.opacity="1"; });
  setTimeout(()=>{ n.style.top="-70px"; n.style.opacity="0"; setTimeout(()=>n.remove(),420); },2500);
}

/* Shell runner */
async function runShell(cmd) {
  if (!cmd || typeof ksu?.exec !== "function") throw new Error("KSU API unavailable");
  return new Promise((res, rej) => {
    const cb = `cb_${Date.now()}_${Math.random()*10000|0}`;
    window[cb] = (code, stdout, stderr) => {
      delete window[cb];
      code === 0 ? res((stdout||"").replace(/\r/g,"")) : rej(new Error(stderr||stdout||"Shell failed"));
    };
    ksu.exec(cmd, "{}", cb);
  });
}

/* Fullscreen */
function enableFullScreen() {
  try {
    if (window.kernelsu?.fullScreen) return window.kernelsu.fullScreen(true);
    if (window.fullScreen) return window.fullScreen(true);
    if (ksu?.fullScreen) return ksu.fullScreen(true);
    document.documentElement.requestFullscreen?.().catch(()=>{});
  } catch {}
}

/* Iframe opener */
function openIframe(url,label=""){
  const iframe=document.createElement("iframe");
  iframe.src=url;
  Object.assign(iframe.style,{position:"fixed",top:0,left:0,width:"100vw",height:"100vh",border:"none",zIndex:9998,background:"black"});
  const btn=document.createElement("button");
  btn.textContent="⟵ Back";
  Object.assign(btn.style,{position:"fixed",top:"10px",left:"10px",zIndex:9999,padding:"8px 14px",background:"transparent",color:"white",border:"none",cursor:"pointer"});
  btn.onclick=()=>{iframe.remove();btn.remove();};
  document.body.append(iframe,btn);
}

/* Dashboard */
async function updateDashboard() {
  const statusItems = {
    "status-playstore": "dumpsys package com.android.vending | grep versionName | head -n1 | awk -F'=' '{print $2}' | cut -d'-' -f1 | cut -d' ' -f1 | cut -d'.' -f1-3",
    "status-playservices": "dumpsys package com.google.android.gms | grep versionName | head -n1 | awk -F'=' '{print $2}' | cut -d'-' -f1 | cut -d' ' -f1 | cut -d'.' -f1-3",
    "status-selinux": "getenforce || echo Unknown",
    "status-target": "[ -f /data/adb/tricky_store/target.txt ] && grep -cve '^$' /data/adb/tricky_store/target.txt || echo 0",
    "status-android": "getprop ro.build.version.release || echo Unknown",
    "status-patch": "getprop ro.build.version.security_patch || echo Unknown",
    "status-whitelist": "[ -f /data/adb/nohello/whitelist ] || [ -f /data/adb/shamiko/whitelist ] && echo Enabled || echo Disabled",

    "status-gms": `
      props=(
        persist.sys.pihooks.disable.gms_key_attestation_block
        persist.sys.pihooks.disable.gms_props
        persist.sys.pihooks.disable
        persist.sys.kihooks.disable
      );
      found_any=0; disabled=0; enabled=0;
      for p in "\${props[@]}"; do
        val=$(getprop "$p" 2>/dev/null);
        if [ -n "$val" ]; then
          found_any=1;
          if [ "$val" = "true" ] || [ "$val" = "1" ]; then
            disabled=$((disabled+1));
          elif [ "$val" = "false" ] || [ "$val" = "0" ]; then
            enabled=$((enabled+1));
          fi;
        fi;
      done;
      if [ $found_any -eq 0 ]; then echo "PIF";
      elif [ $enabled -gt 0 ]; then echo "ENABLED";
      else echo "DISABLED"; fi
    `,

    "status-LineageProp": `if getprop | grep -iq 'lineage'; then echo FOUND; else echo NONE; fi`
  };

  for (const [id, cmd] of Object.entries(statusItems)) {
    const el = document.getElementById(id);
    if (!el) continue;
    try {
      let out = (await runShell(cmd)).trim();
      if (!out) out = id === "status-whitelist" ? "Disabled" : "Unknown";

      switch (id) {
        case "status-selinux":
          el.textContent = out;
          el.className = `status-indicator ${
            out === "Enforcing" ? "enabled" : out === "Permissive" ? "disabled" : "neutral"
          }`;
          break;

        case "status-target":
          el.textContent = `${out} apps`;
          el.className = `status-indicator ${out === "0" ? "disabled" : "enabled"}`;
          break;

        case "status-gms":
          if (out === "DISABLED") {
            el.textContent = "Disabled";
            el.className = "status-indicator disabled";
          } else if (out === "ENABLED") {
            el.textContent = "Enabled";
            el.className = "status-indicator enabled";
          } else if (out === "PIF") {
            el.textContent = "PIF";
            el.className = "status-indicator neutral";
          } else {
            el.textContent = "Unknown";
            el.className = "status-indicator neutral";
          }
          break;

        case "status-LineageProp":
          if (out === "FOUND") {
            el.textContent = "Detected";
            el.className = "status-indicator disabled";
          } else {
            el.textContent = "Spoofed";
            el.className = "status-indicator enabled";
          }
          break;

        default:
          el.textContent = out;
          el.className = `status-indicator ${out === "Unknown" ? "disabled" : "neutral"}`;
      }
    } catch {
      el.textContent = "Unknown";
      el.className = "status-indicator disabled";
    }
  }
}

/* Button actions */
btns.forEach(btn=>{
  if(btn._attached) return;
  btn._attached=true;
  btn.addEventListener("click",async ()=>{
    const script=btn.dataset.script;
    const type=btn.dataset.type;
    const label=btn.dataset.origLabel||script;
    btn.classList.add("loading");

    try {
      if (messageMap[script]?.start) popup(messageMap[script].start, messageMap[script].type);

      if (["scanner","hash","user","flags","piffork","pif","vending","support"].includes(type)) {
        const pathMap={scanner:"./Risky/index.html",hash:"./BootHash/index.html",flags:"./Flags/index.html",piffork:"./PlayIntegrityFork/index.html",pif:"./CustomPIF/index.html",vending:"./Certified/index.html",support:"./Support/index.html",user:"./TrickyStore/index.html"};
        return openIframe(pathMap[type],label);
      }

      if(script) await runShell(`sh ${MODDIR}/${script}`);

      if (messageMap[script]?.success)
        popup(messageMap[script].success, messageMap[script].type);

    } catch(e) {
      popup(`Error: ${e.message}`,"error");
    } finally {
      btn.classList.remove("loading");
      setTimeout(updateDashboard,500);
    }
  });
});

/* Initialize */
document.addEventListener("DOMContentLoaded",()=>{
  enableFullScreen();
  updateDashboard();
});
