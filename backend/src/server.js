const path = require("path");
const fs = require("fs");
require("dotenv").config();
const express=require("express"),cors=require("cors"),fs=require("fs"),path=require("path");
const app=express(),PORT=process.env.PORT||10000,DATA=path.join(__dirname,"..","data");
app.use(cors({origin:true,credentials:true}));
app.use((req, res, next) => {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Methods", "GET,POST,PUT,DELETE,OPTIONS");
  res.header("Access-Control-Allow-Headers", "Content-Type, Authorization");
  if (req.method === "OPTIONS") return res.sendStatus(200);
  next();
});

app.use(express.json({limit:"20mb"}));
function fp(n){if(!fs.existsSync(DATA))fs.mkdirSync(DATA,{recursive:true});return path.join(DATA,n)}
function read(n,f){const p=fp(n);if(!fs.existsSync(p)){fs.writeFileSync(p,JSON.stringify(f,null,2));return f}try{return JSON.parse(fs.readFileSync(p,"utf8"))}catch{return f}}
function write(n,d){fs.writeFileSync(fp(n),JSON.stringify(d,null,2))}
function id(p){return `${p}_${Date.now()}_${Math.random().toString(16).slice(2,8)}`}
function admin(req,res,next){const t=String(req.headers.authorization||"").replace("Bearer ","");if(t==="reza-v11-admin-token")return next();res.status(401).json({success:false,message:"Unauthorized"})}

// ================================
// REZA MEDIA API - FINAL
// ================================
const rezaMediaFile = path.join(__dirname, "../data/media.json");

function getDefaultMedia() {
  return {
    heroImage: "assets/images/reza-soft-beauty-bg.svg",
    heroTitle: "Champagne Luxury",
    updatedAt: new Date().toISOString()
  };
}

function readRezaMedia() {
  try {
    fs.mkdirSync(path.dirname(rezaMediaFile), { recursive: true });

    if (!fs.existsSync(rezaMediaFile)) {
      const defaults = getDefaultMedia();
      fs.writeFileSync(rezaMediaFile, JSON.stringify(defaults, null, 2));
      return defaults;
    }

    const raw = fs.readFileSync(rezaMediaFile, "utf8");
    return JSON.parse(raw || "{}");
  } catch (error) {
    return getDefaultMedia();
  }
}

app.get("/api/media", (req, res) => {
  res.json({
    success: true,
    media: readRezaMedia()
  });
});

app.post("/api/media", express.json({ limit: "60mb" }), (req, res) => {
  try {
    const current = readRezaMedia();

    const next = {
      ...current,
      ...req.body,
      updatedAt: new Date().toISOString()
    };

    fs.mkdirSync(path.dirname(rezaMediaFile), { recursive: true });
    fs.writeFileSync(rezaMediaFile, JSON.stringify(next, null, 2));

    res.json({
      success: true,
      message: "Media saved successfully",
      media: next
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});


app.get("/api/health",(req,res)=>res.json({success:true,message:"Reza V11 Champagne API online",time:new Date().toISOString()}));
app.post("/api/auth/login",(req,res)=>{const {email,password}=req.body||{};if(email==="admin@reza.co.za"&&password==="reza2026")return res.json({success:true,token:"reza-v11-admin-token",user:{email,name:"Reza Admin"}});res.status(401).json({success:false,message:"Invalid login"})});
app.get("/api/products",(req,res)=>res.json({success:true,products:read("products.json",[])}));
app.get("/api/products/:id",(req,res)=>{const p=read("products.json",[]).find(x=>String(x.id)===String(req.params.id));if(!p)return res.status(404).json({success:false,message:"Product not found"});res.json({success:true,product:p})});
app.post("/api/products",admin,(req,res)=>{let ps=read("products.json",[]),b=req.body||{};let p={id:b.id||id("product"),name:b.name||"New Product",category:b.category||"Beauty",price:Number(b.price||0),stock:Number(b.stock||0),badge:b.badge||"",image:b.image||"",description:b.description||"",benefits:Array.isArray(b.benefits)?b.benefits:[],howToUse:b.howToUse||"",showOnline:b.showOnline!==false,createdAt:new Date().toISOString(),updatedAt:new Date().toISOString()};ps.unshift(p);write("products.json",ps);res.json({success:true,product:p,products:ps})});
app.put("/api/products/:id",admin,(req,res)=>{let ps=read("products.json",[]),i=ps.findIndex(p=>String(p.id)===String(req.params.id));if(i<0)return res.status(404).json({success:false,message:"Product not found"});ps[i]={...ps[i],...req.body,id:req.params.id,price:Number(req.body.price??ps[i].price??0),stock:Number(req.body.stock??ps[i].stock??0),updatedAt:new Date().toISOString()};write("products.json",ps);res.json({success:true,product:ps[i],products:ps})});
app.delete("/api/products/:id",admin,(req,res)=>{let ps=read("products.json",[]).filter(p=>String(p.id)!==String(req.params.id));write("products.json",ps);res.json({success:true,products:ps})});
app.get("/api/media",(req,res)=>res.json({success:true,media:read("media.json",{})}));
app.put("/api/media",admin,(req,res)=>{let m={...read("media.json",{}),...req.body,updatedAt:new Date().toISOString()};write("media.json",m);res.json({success:true,media:m})});
app.get("/api/orders",admin,(req,res)=>res.json({success:true,orders:read("orders.json",[])}));
app.post("/api/orders",(req,res)=>{let os=read("orders.json",[]),b=req.body||{},total=(b.items||[]).reduce((s,i)=>s+Number(i.price||0)*Number(i.qty||1),0);let o={id:id("order"),orderNumber:`REZA-${Date.now()}`,customer:b.customer||{},items:b.items||[],total,status:"New Order",paymentStatus:"Pending",createdAt:new Date().toISOString()};os.unshift(o);write("orders.json",os);res.json({success:true,order:o,message:"Order created successfully."})});
app.get("/api/payments/yoco/diagnostics",(req,res)=>{const key=process.env.YOCO_SECRET_KEY||"";res.json({success:true,yocoConfigured:Boolean(key),keyMode:key.startsWith("sk_live_")||key.startsWith("yoco_live_")?"live":key.startsWith("sk_test_")||key.startsWith("yoco_test_")?"test":"unknown",webhookConfigured:Boolean(process.env.YOCO_WEBHOOK_SECRET),frontendUrl:process.env.FRONTEND_URL||null,webhookUrl:"/api/payments/yoco/webhook"})});
app.post("/api/payments/yoco/webhook",(req,res)=>{console.log("Yoco webhook",JSON.stringify(req.body).slice(0,600));res.json({success:true,received:true})});
app.use((req,res)=>res.status(404).json({success:false,message:"Route not found"}));
// ================================
// WORKING REZA MEDIA API
// ================================
const rezaMediaPath = path.join(__dirname, "../data/media.json");

function readRezaMediaSafe() {
  try {
    fs.mkdirSync(path.dirname(rezaMediaPath), { recursive: true });
    if (!fs.existsSync(rezaMediaPath)) {
      const defaults = {
        heroImage: "assets/images/reza-soft-beauty-bg.svg",
        heroTitle: "Champagne Luxury",
        updatedAt: new Date().toISOString()
      };
      fs.writeFileSync(rezaMediaPath, JSON.stringify(defaults, null, 2));
      return defaults;
    }
    return JSON.parse(fs.readFileSync(rezaMediaPath, "utf8"));
  } catch (err) {
    return {
      heroImage: "assets/images/reza-soft-beauty-bg.svg",
      heroTitle: "Champagne Luxury",
      error: err.message
    };
  }
}

app.get("/api/media", (req, res) => {
  res.json({ success: true, media: readRezaMediaSafe() });
});

app.post("/api/media", express.json({ limit: "80mb" }), (req, res) => {
  try {
    const current = readRezaMediaSafe();
    const next = {
      ...current,
      heroImage: req.body.heroImage || current.heroImage,
      heroTitle: req.body.heroTitle || current.heroTitle || "Champagne Luxury",
      updatedAt: new Date().toISOString()
    };

    fs.mkdirSync(path.dirname(rezaMediaPath), { recursive: true });
    fs.writeFileSync(rezaMediaPath, JSON.stringify(next, null, 2));

    res.json({
      success: true,
      message: "Media saved successfully",
      media: next
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      message: err.message
    });
  }
});



// ================================
// REZA MEDIA ROUTES - FORCED LIVE
// ================================
const REZA_MEDIA_FILE_FINAL = path.join(__dirname, "../data/media.json");

function rezaDefaultMediaFinal() {
  return {
    heroImage: "assets/images/reza-soft-beauty-bg.svg",
    heroTitle: "Champagne Luxury",
    updatedAt: new Date().toISOString()
  };
}

function rezaReadMediaFinal() {
  try {
    fs.mkdirSync(path.dirname(REZA_MEDIA_FILE_FINAL), { recursive: true });

    if (!fs.existsSync(REZA_MEDIA_FILE_FINAL)) {
      const defaults = rezaDefaultMediaFinal();
      fs.writeFileSync(REZA_MEDIA_FILE_FINAL, JSON.stringify(defaults, null, 2));
      return defaults;
    }

    return JSON.parse(fs.readFileSync(REZA_MEDIA_FILE_FINAL, "utf8"));
  } catch (error) {
    return {
      ...rezaDefaultMediaFinal(),
      error: error.message
    };
  }
}

app.get("/api/media", (req, res) => {
  res.json({
    success: true,
    media: rezaReadMediaFinal()
  });
});

app.post("/api/media", (req, res) => {
  try {
    const current = rezaReadMediaFinal();

    const next = {
      ...current,
      heroImage: req.body.heroImage || current.heroImage,
      heroTitle: req.body.heroTitle || current.heroTitle || "Champagne Luxury",
      updatedAt: new Date().toISOString()
    };

    fs.mkdirSync(path.dirname(REZA_MEDIA_FILE_FINAL), { recursive: true });
    fs.writeFileSync(REZA_MEDIA_FILE_FINAL, JSON.stringify(next, null, 2));

    res.json({
      success: true,
      message: "Media saved successfully",
      media: next
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

// END REZA MEDIA ROUTES - FORCED LIVE

app.listen(PORT,()=>console.log(`Reza V11 API running on port ${PORT}`));
