const puppeteer = require('puppeteer');
const path = require('path');
const fs = require('fs');
const { execSync } = require('child_process');

const OUTPUT_DIR = path.join(__dirname, 'output');
const FRAME_DIR = path.join(__dirname, 'frames');
const WIDTH = 1080;
const HEIGHT = 1920;
const FPS = 30;
const STORY_DURATION_SEC = 5;
const TOTAL_FRAMES = FPS * STORY_DURATION_SEC;

const STORY_NAMES = [
  'story-1-brand-intro',
  'story-2-connect',
  'story-3-discover',
  'story-4-how-it-works',
  'story-5-ambassador',
];

// Each story as a standalone HTML (no iPhone frame, full 1080x1920)
function buildStoryHTML(storyIndex) {
  // We reuse the same styles/content but render only one story at a time,
  // full-bleed at 1080x1920 with auto-play animation
  return `<!DOCTYPE html>
<html><head>
<meta charset="UTF-8">
<link href="https://fonts.googleapis.com/css2?family=Rubik:wght@600;700;800&family=Open+Sans:wght@400;600;700&family=DM+Sans:wght@500;600;700&display=swap" rel="stylesheet">
<style>
* { margin:0; padding:0; box-sizing:border-box; }
html,body { width:${WIDTH}px; height:${HEIGHT}px; overflow:hidden; -webkit-font-smoothing:antialiased; }
.story { width:${WIDTH}px; height:${HEIGHT}px; display:flex; flex-direction:column; align-items:center; justify-content:center; position:relative; overflow:hidden; }

/* Progress bar */
.progress-bar { position:absolute; top:60px; left:40px; right:40px; display:flex; gap:12px; z-index:100; }
.progress-seg { flex:1; height:6px; background:rgba(255,255,255,0.2); border-radius:3px; overflow:hidden; }
.progress-seg .fill { height:100%; width:0%; background:#FFD861; border-radius:3px; }
.progress-seg.done .fill { width:100%; }

/* ─── S1 ─── */
.story-1 { background:#000; }
.s1-glow { position:absolute; width:900px; height:900px; border-radius:50%; background:radial-gradient(circle,rgba(255,216,97,0.22)0%,transparent 70%); top:50%; left:50%; transform:translate(-50%,-50%) scale(0); }
.s1-ring { position:absolute; border:3px solid rgba(255,216,97,0.12); border-radius:50%; top:50%; left:50%; transform:translate(-50%,-50%) scale(0); }
.s1-ring-1 { width:500px; height:500px; }
.s1-ring-2 { width:720px; height:720px; }
.s1-ring-3 { width:940px; height:940px; }
.s1-logo { width:260px; height:260px; background:#FFD861; border-radius:50%; display:flex; align-items:center; justify-content:center; position:relative; z-index:2; transform:scale(0); }
.s1-logo span { font-family:'Rubik',sans-serif; font-size:150px; font-weight:800; color:#000; }
.s1-name { font-family:'Rubik',sans-serif; font-size:92px; font-weight:800; color:#FFD861; letter-spacing:5px; text-transform:uppercase; margin-top:50px; position:relative; z-index:2; opacity:0; transform:translateY(50px); }
.s1-tagline { font-family:'Open Sans',sans-serif; font-size:36px; color:rgba(255,255,255,0.6); margin-top:20px; text-align:center; max-width:700px; line-height:1.45; position:relative; z-index:2; opacity:0; transform:translateY(30px); }
.s1-particle { position:absolute; width:10px; height:10px; background:#FFD861; border-radius:50%; opacity:0; }

/* ─── S2 ─── */
.story-2 { background:#FFD861; }
.s2-corner { position:absolute; width:200px; height:200px; border:5px solid rgba(0,0,0,0.07); border-radius:40px; opacity:0; }
.s2-corner-tl { top:-30px; left:-30px; }
.s2-corner-br { bottom:-30px; right:-30px; }
.s2-dots { position:absolute; top:140px; right:80px; display:grid; grid-template-columns:repeat(5,1fr); gap:20px; }
.s2-dot { width:12px; height:12px; background:rgba(0,0,0,0.1); border-radius:50%; transform:scale(0); }
.s2-word { font-family:'Rubik',sans-serif; font-size:100px; font-weight:800; color:#000; text-transform:uppercase; line-height:1.05; text-align:center; opacity:0; transform:translateY(100px); }
.s2-sub { font-family:'Open Sans',sans-serif; font-size:38px; color:rgba(0,0,0,0.55); text-align:center; max-width:780px; line-height:1.45; margin-top:44px; opacity:0; transform:translateY(30px); }
.s2-icons { display:flex; gap:56px; margin-top:70px; position:relative; z-index:2; }
.s2-icon { width:160px; height:160px; background:#000; border-radius:50%; display:flex; align-items:center; justify-content:center; flex-direction:column; gap:6px; transform:scale(0); }
.s2-icon svg { width:56px; height:56px; stroke:#FFD861; fill:none; stroke-width:2; }
.s2-icon-label { font-family:'DM Sans',sans-serif; font-size:17px; font-weight:600; color:#FFD861; text-transform:uppercase; letter-spacing:1px; }

/* ─── S3 ─── */
.story-3 { background:linear-gradient(180deg,#000 0%,#111 100%); }
.s3-glow { position:absolute; width:550px; height:550px; border-radius:50%; background:radial-gradient(circle,rgba(255,216,97,0.1)0%,transparent 70%); bottom:-100px; right:-100px; }
.s3-label { font-family:'DM Sans',sans-serif; font-size:28px; font-weight:600; color:#FFD861; text-transform:uppercase; letter-spacing:5px; margin-bottom:24px; opacity:0; transform:translateX(-80px); }
.s3-headline { font-family:'Rubik',sans-serif; font-size:80px; font-weight:800; color:#fff; text-align:center; line-height:1.12; text-transform:uppercase; opacity:0; transform:translateY(60px) scale(0.85); }
.s3-cards { margin-top:70px; position:relative; width:820px; height:650px; }
.s3-card { position:absolute; width:760px; left:50%; background:#FFF6D8; border:2px solid #F9E9AC; border-radius:24px; padding:46px; transform:translateX(-50%) translateY(350px); opacity:0; }
.s3-card-1 { z-index:3; } .s3-card-2 { z-index:2; } .s3-card-3 { z-index:1; }
.s3-badge { display:inline-block; background:#D4EDDA; color:#155724; font-family:'DM Sans',sans-serif; font-size:22px; font-weight:600; padding:8px 24px; border-radius:999px; text-transform:uppercase; letter-spacing:1px; }
.s3-card-title { font-family:'Rubik',sans-serif; font-size:42px; font-weight:700; color:#232323; margin-top:20px; line-height:1.2; }
.s3-card-meta { font-family:'Open Sans',sans-serif; font-size:28px; color:#606060; margin-top:12px; }
.s3-tags { display:flex; gap:14px; margin-top:18px; flex-wrap:wrap; }
.s3-tag { background:#FFDDAC; color:#D8910B; font-family:'DM Sans',sans-serif; font-size:20px; font-weight:600; padding:8px 20px; border-radius:999px; transform:scale(0); }

/* ─── S4 ─── */
.story-4 { background:#FFD861; }
.s4-label { font-family:'DM Sans',sans-serif; font-size:28px; font-weight:600; color:rgba(0,0,0,0.4); text-transform:uppercase; letter-spacing:4px; margin-bottom:16px; opacity:0; transform:translateY(-30px); }
.s4-headline { font-family:'Rubik',sans-serif; font-size:84px; font-weight:800; color:#000; text-transform:uppercase; text-align:center; line-height:1.05; opacity:0; transform:scale(0.5); }
.s4-steps { display:flex; flex-direction:column; align-items:center; gap:0; margin-top:60px; }
.s4-step { display:flex; align-items:center; gap:36px; width:820px; opacity:0; transform:translateX(60px); }
.s4-num { width:100px; height:100px; min-width:100px; background:#000; border-radius:50%; display:flex; align-items:center; justify-content:center; font-family:'Rubik',sans-serif; font-size:48px; font-weight:800; color:#FFD861; }
.s4-step-title { font-family:'Rubik',sans-serif; font-size:42px; font-weight:700; color:#000; text-transform:uppercase; }
.s4-step-desc { font-family:'Open Sans',sans-serif; font-size:28px; color:rgba(0,0,0,0.5); margin-top:6px; line-height:1.35; }
.s4-line { width:4px; height:36px; background:rgba(0,0,0,0.1); margin:12px 0 12px 48px; transform:scaleY(0); transform-origin:top; }

/* ─── S5 ─── */
.story-5 { background:#000; }
.s5-ring { position:absolute; border:3px solid rgba(255,216,97,0.12); border-radius:50%; top:50%; left:50%; transform:translate(-50%,-50%) scale(0); opacity:0; }
.s5-ring-1 { width:420px; height:420px; }
.s5-ring-2 { width:650px; height:650px; }
.s5-ring-3 { width:880px; height:880px; }
.s5-exclusive { font-family:'DM Sans',sans-serif; font-size:24px; font-weight:700; color:#000; background:#FFD861; padding:12px 40px; border-radius:999px; text-transform:uppercase; letter-spacing:4px; margin-bottom:50px; opacity:0; transform:translateY(-30px); }
.s5-logo { width:200px; height:200px; background:#FFD861; border-radius:50%; display:flex; align-items:center; justify-content:center; margin-bottom:44px; transform:scale(0) translateY(-100px); }
.s5-logo span { font-family:'Rubik',sans-serif; font-size:116px; font-weight:800; color:#000; }
.s5-headline { font-family:'Rubik',sans-serif; font-size:72px; font-weight:800; color:#fff; text-transform:uppercase; text-align:center; line-height:1.12; max-width:900px; opacity:0; transform:translateY(50px); }
.s5-highlight { color:#FFD861; }
.s5-sub { font-family:'Open Sans',sans-serif; font-size:34px; color:rgba(255,255,255,0.5); text-align:center; margin-top:32px; max-width:750px; line-height:1.45; opacity:0; transform:translateY(20px); }
.s5-perks { margin-top:50px; display:flex; flex-direction:column; gap:18px; width:800px; }
.s5-perk { display:flex; align-items:center; gap:22px; background:rgba(255,216,97,0.06); border:2px solid rgba(255,216,97,0.12); border-radius:20px; padding:24px 30px; opacity:0; transform:translateX(-40px); }
.s5-perk-icon { width:64px; height:64px; min-width:64px; background:#FFD861; border-radius:50%; display:flex; align-items:center; justify-content:center; font-size:30px; }
.s5-perk-text { font-family:'DM Sans',sans-serif; font-size:28px; font-weight:600; color:rgba(255,255,255,0.8); }
.s5-btn { margin-top:50px; background:#FFD861; color:#000; font-family:'DM Sans',sans-serif; font-size:36px; font-weight:700; text-transform:uppercase; letter-spacing:3px; padding:28px 80px; border-radius:16px; border:none; transform:scale(0); }
.s5-limited { font-family:'Open Sans',sans-serif; font-size:24px; color:rgba(255,255,255,0.3); margin-top:20px; text-align:center; opacity:0; }
.s5-bottom { position:absolute; bottom:60px; display:flex; gap:12px; align-items:center; opacity:0; transform:translateY(20px); }
.s5-bottom span { font-family:'DM Sans',sans-serif; font-size:24px; color:rgba(255,255,255,0.3); text-transform:uppercase; letter-spacing:2px; }
</style>
</head><body>
__STORY_HTML__
<script src="https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.5/gsap.min.js"></script>
<script>
window.__ANIMATION_READY__ = false;
// Wait for fonts then signal ready
document.fonts.ready.then(() => {
  window.__ANIMATION_READY__ = true;
});
window.__playAnimation__ = function() {
  __ANIMATION_JS__
};
</script>
</body></html>`;
}

const STORY_HTML = [
  // Story 1
  `<div class="story story-1" style="opacity:1;visibility:visible">
    <div class="progress-bar"><div class="progress-seg"><div class="fill" id="pf"></div></div></div>
    <div class="s1-glow"></div>
    <div class="s1-ring s1-ring-1"></div><div class="s1-ring s1-ring-2"></div><div class="s1-ring s1-ring-3"></div>
    <div class="s1-particle" style="top:14%;left:18%"></div><div class="s1-particle" style="top:22%;right:14%"></div>
    <div class="s1-particle" style="top:68%;left:10%"></div><div class="s1-particle" style="top:73%;right:18%"></div>
    <div class="s1-particle" style="top:32%;left:7%"></div><div class="s1-particle" style="top:58%;right:9%"></div>
    <div class="s1-particle" style="top:9%;left:48%"></div><div class="s1-particle" style="top:83%;left:38%"></div>
    <div class="s1-logo"><span>K</span></div>
    <div class="s1-name">Kolabing</div>
    <div class="s1-tagline">Where businesses & communities create magic together</div>
  </div>`,

  // Story 2
  `<div class="story story-2" style="opacity:1;visibility:visible">
    <div class="progress-bar"><div class="progress-seg done"><div class="fill" style="width:100%"></div></div><div class="progress-seg"><div class="fill" id="pf"></div></div></div>
    <div class="s2-corner s2-corner-tl"></div><div class="s2-corner s2-corner-br"></div>
    <div class="s2-dots"><div class="s2-dot"></div><div class="s2-dot"></div><div class="s2-dot"></div><div class="s2-dot"></div><div class="s2-dot"></div><div class="s2-dot"></div><div class="s2-dot"></div><div class="s2-dot"></div><div class="s2-dot"></div><div class="s2-dot"></div><div class="s2-dot"></div><div class="s2-dot"></div><div class="s2-dot"></div><div class="s2-dot"></div><div class="s2-dot"></div></div>
    <div class="s2-word">Connect</div><div class="s2-word">&</div><div class="s2-word">Collaborate</div>
    <div class="s2-sub">Kolabing brings businesses and communities together for meaningful partnerships</div>
    <div class="s2-icons">
      <div class="s2-icon"><svg viewBox="0 0 24 24"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg><span class="s2-icon-label">Chat</span></div>
      <div class="s2-icon"><svg viewBox="0 0 24 24"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg><span class="s2-icon-label">Team</span></div>
      <div class="s2-icon"><svg viewBox="0 0 24 24"><path d="M12 2L2 7l10 5 10-5-10-5z"/><path d="M2 17l10 5 10-5"/><path d="M2 12l10 5 10-5"/></svg><span class="s2-icon-label">Build</span></div>
    </div>
  </div>`,

  // Story 3
  `<div class="story story-3" style="opacity:1;visibility:visible">
    <div class="progress-bar"><div class="progress-seg done"><div class="fill" style="width:100%"></div></div><div class="progress-seg done"><div class="fill" style="width:100%"></div></div><div class="progress-seg"><div class="fill" id="pf"></div></div></div>
    <div class="s3-glow"></div>
    <div class="s3-label">Find your match</div>
    <div class="s3-headline">Discover<br>Opportunities</div>
    <div class="s3-cards">
      <div class="s3-card s3-card-3"><div class="s3-badge">Active</div><div class="s3-card-title">Tech Meetup Sponsor</div><div class="s3-card-meta">San Francisco, CA</div></div>
      <div class="s3-card s3-card-2"><div class="s3-badge">Active</div><div class="s3-card-title">Community Workshop</div><div class="s3-card-meta">Austin, TX</div></div>
      <div class="s3-card s3-card-1"><div class="s3-badge">Active</div><div class="s3-card-title">Brand Partnership</div><div class="s3-card-meta">New York, NY</div><div class="s3-tags"><span class="s3-tag">Marketing</span><span class="s3-tag">Events</span><span class="s3-tag">Social</span></div></div>
    </div>
  </div>`,

  // Story 4
  `<div class="story story-4" style="opacity:1;visibility:visible">
    <div class="progress-bar"><div class="progress-seg done"><div class="fill" style="width:100%"></div></div><div class="progress-seg done"><div class="fill" style="width:100%"></div></div><div class="progress-seg done"><div class="fill" style="width:100%"></div></div><div class="progress-seg"><div class="fill" id="pf"></div></div></div>
    <div class="s4-label">How it works</div>
    <div class="s4-headline">Apply<br>With Ease</div>
    <div class="s4-steps">
      <div class="s4-step"><div class="s4-num">1</div><div><div class="s4-step-title">Browse</div><div class="s4-step-desc">Discover opportunities by location & category</div></div></div>
      <div class="s4-line"></div>
      <div class="s4-step"><div class="s4-num">2</div><div><div class="s4-step-title">Apply</div><div class="s4-step-desc">Submit applications with just a few taps</div></div></div>
      <div class="s4-line"></div>
      <div class="s4-step"><div class="s4-num">3</div><div><div class="s4-step-title">Collaborate</div><div class="s4-step-desc">Manage partnerships and grow together</div></div></div>
    </div>
  </div>`,

  // Story 5
  `<div class="story story-5" style="opacity:1;visibility:visible">
    <div class="progress-bar"><div class="progress-seg done"><div class="fill" style="width:100%"></div></div><div class="progress-seg done"><div class="fill" style="width:100%"></div></div><div class="progress-seg done"><div class="fill" style="width:100%"></div></div><div class="progress-seg done"><div class="fill" style="width:100%"></div></div><div class="progress-seg"><div class="fill" id="pf"></div></div></div>
    <div class="s5-ring s5-ring-1"></div><div class="s5-ring s5-ring-2"></div><div class="s5-ring s5-ring-3"></div>
    <div class="s5-exclusive">Early Ambassador</div>
    <div class="s5-logo"><span>K</span></div>
    <div class="s5-headline">Be Among The<br><span class="s5-highlight">First Businesses</span><br>On Kolabing</div>
    <div class="s5-sub">Join as an early ambassador and shape the future of collaboration</div>
    <div class="s5-perks">
      <div class="s5-perk"><div class="s5-perk-icon">&#9733;</div><div class="s5-perk-text">Priority listing & verified badge</div></div>
      <div class="s5-perk"><div class="s5-perk-icon">&#128142;</div><div class="s5-perk-text">Free premium features for 6 months</div></div>
      <div class="s5-perk"><div class="s5-perk-icon">&#127793;</div><div class="s5-perk-text">Direct access to top communities</div></div>
    </div>
    <div class="s5-btn">Apply Now</div>
    <div class="s5-limited">Limited spots available</div>
    <div class="s5-bottom"><span>Swipe up to apply</span><svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,0.35)" stroke-width="2.5"><path d="M12 19V5M5 12l7-7 7 7"/></svg></div>
  </div>`,
];

const STORY_ANIMATIONS = [
  // Story 1
  `const tl=gsap.timeline();
  tl.to('.s1-glow',{scale:1,duration:1,ease:'power2.out'})
    .to('.s1-logo',{scale:1,duration:0.7,ease:'back.out(1.7)'},0.1)
    .to('.s1-ring',{scale:1,stagger:0.12,duration:0.6,ease:'power2.out'},0.25)
    .to('.s1-name',{y:0,opacity:1,duration:0.5,ease:'power3.out'},0.6)
    .to('.s1-tagline',{y:0,opacity:1,duration:0.4,ease:'power3.out'},0.8)
    .to('.s1-particle',{opacity:0.6,stagger:{each:0.05,from:'random'},duration:0.3},0.9)
    .to('.s1-particle',{y:'-=25',x:'random(-20,20)',duration:1.5,stagger:0.06,yoyo:true,repeat:1,ease:'sine.inOut'},1.1);
  gsap.fromTo('#pf',{width:'0%'},{width:'100%',duration:5,ease:'none'});`,

  // Story 2
  `const tl=gsap.timeline();
  tl.to('.s2-word',{y:0,opacity:1,stagger:0.15,duration:0.5,ease:'power4.out'})
    .to('.s2-sub',{y:0,opacity:1,duration:0.4},0.6)
    .to('.s2-icon',{scale:1,stagger:0.12,duration:0.5,ease:'back.out(1.4)'},0.8)
    .to('.s2-dot',{scale:1,stagger:{each:0.02,from:'random'},duration:0.2},0.7)
    .to('.s2-corner-tl',{opacity:1,duration:0.5},0.4)
    .to('.s2-corner-br',{opacity:1,duration:0.5},0.4);
  gsap.fromTo('#pf',{width:'0%'},{width:'100%',duration:5,ease:'none'});`,

  // Story 3
  `const tl=gsap.timeline();
  tl.to('.s3-label',{x:0,opacity:1,duration:0.4})
    .to('.s3-headline',{y:0,opacity:1,scale:1,duration:0.6,ease:'power3.out'},0.15)
    .to('.s3-card-3',{y:60,opacity:1,rotation:2,duration:0.5},0.4)
    .to('.s3-card-2',{y:30,opacity:1,rotation:-1.5,duration:0.5},0.55)
    .to('.s3-card-1',{y:0,opacity:1,duration:0.5,ease:'power2.out'},0.7)
    .to('.s3-tag',{scale:1,stagger:0.08,duration:0.3,ease:'back.out(2)'},1);
  gsap.fromTo('#pf',{width:'0%'},{width:'100%',duration:5,ease:'none'});`,

  // Story 4
  `const tl=gsap.timeline();
  tl.to('.s4-label',{y:0,opacity:1,duration:0.35})
    .to('.s4-headline',{scale:1,opacity:1,duration:0.6,ease:'power3.out'},0.1);
  document.querySelectorAll('.s4-step').forEach((s,i)=>{
    tl.to(s,{x:0,opacity:1,duration:0.4,ease:'power2.out'},0.5+i*0.3);
  });
  document.querySelectorAll('.s4-line').forEach((l,i)=>{
    tl.to(l,{scaleY:1,duration:0.25},0.7+i*0.3);
  });
  gsap.fromTo('#pf',{width:'0%'},{width:'100%',duration:5,ease:'none'});`,

  // Story 5
  `const tl=gsap.timeline();
  tl.to('.s5-ring',{scale:1,opacity:1,stagger:0.15,duration:0.7})
    .to('.s5-exclusive',{y:0,opacity:1,duration:0.4},0.2)
    .to('.s5-logo',{scale:1,y:0,duration:0.6,ease:'bounce.out'},0.3)
    .to('.s5-headline',{y:0,opacity:1,duration:0.5},0.6)
    .to('.s5-sub',{y:0,opacity:1,duration:0.4},0.85)
    .to('.s5-perk',{x:0,opacity:1,stagger:0.12,duration:0.4,ease:'power2.out'},1)
    .to('.s5-btn',{scale:1,duration:0.4,ease:'back.out(2)'},1.4)
    .to('.s5-limited',{opacity:1,duration:0.3},1.6)
    .to('.s5-bottom',{y:0,opacity:1,duration:0.3},1.7)
    .to('.s5-btn',{scale:1.06,duration:0.35,yoyo:true,repeat:4,ease:'sine.inOut'},2);
  gsap.fromTo('#pf',{width:'0%'},{width:'100%',duration:5,ease:'none'});`,
];

async function main() {
  // Create dirs
  if (!fs.existsSync(OUTPUT_DIR)) fs.mkdirSync(OUTPUT_DIR, { recursive: true });

  console.log('Launching browser...');
  const browser = await puppeteer.launch({
    headless: 'new',
    args: [`--window-size=${WIDTH},${HEIGHT}`],
  });

  for (let i = 0; i < 5; i++) {
    const storyName = STORY_NAMES[i];
    const frameDir = path.join(FRAME_DIR, storyName);

    // Clean & create frame dir
    if (fs.existsSync(frameDir)) fs.rmSync(frameDir, { recursive: true });
    fs.mkdirSync(frameDir, { recursive: true });

    console.log(`\n[${i + 1}/5] Recording ${storyName}...`);

    // Build HTML
    let html = buildStoryHTML(i)
      .replace('__STORY_HTML__', STORY_HTML[i])
      .replace('__ANIMATION_JS__', STORY_ANIMATIONS[i]);

    const page = await browser.newPage();
    await page.setViewport({ width: WIDTH, height: HEIGHT, deviceScaleFactor: 1 });
    await page.setContent(html, { waitUntil: 'networkidle0', timeout: 15000 });

    // Wait for fonts
    await page.waitForFunction('window.__ANIMATION_READY__ === true', { timeout: 10000 });
    await new Promise(r => setTimeout(r, 500));

    // Capture first frame (before animation)
    const framePath = (n) => path.join(frameDir, `frame_${String(n).padStart(4, '0')}.png`);

    // Capture 5 frames before animation (still)
    for (let f = 0; f < 3; f++) {
      await page.screenshot({ path: framePath(f), type: 'png' });
    }

    // Start animation
    await page.evaluate('window.__playAnimation__()');

    // Capture frames
    const msPerFrame = 1000 / FPS;
    for (let f = 3; f < TOTAL_FRAMES; f++) {
      await new Promise(r => setTimeout(r, msPerFrame));
      await page.screenshot({ path: framePath(f), type: 'png' });
    }

    await page.close();
    console.log(`  Captured ${TOTAL_FRAMES} frames`);

    // Convert frames to MP4 with ffmpeg
    const outputPath = path.join(OUTPUT_DIR, `${storyName}.mp4`);
    console.log(`  Converting to MP4...`);

    try {
      execSync(
        `ffmpeg -y -framerate ${FPS} -i "${frameDir}/frame_%04d.png" ` +
        `-c:v libx264 -pix_fmt yuv420p -crf 18 -preset slow ` +
        `-vf "scale=${WIDTH}:${HEIGHT}" ` +
        `"${outputPath}"`,
        { stdio: 'pipe' }
      );
      console.log(`  Saved: ${outputPath}`);
    } catch (err) {
      console.error(`  ffmpeg error: ${err.message}`);
    }

    // Clean up frames
    fs.rmSync(frameDir, { recursive: true });
  }

  // Clean frames dir
  if (fs.existsSync(FRAME_DIR)) fs.rmSync(FRAME_DIR, { recursive: true });

  await browser.close();
  console.log('\nDone! Videos saved to: instagram-stories/output/');
}

main().catch(console.error);
