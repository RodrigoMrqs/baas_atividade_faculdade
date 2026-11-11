import { initializeApp } from "https://www.gstatic.com/firebasejs/10.14.1/firebase-app.js";
import {
  getAuth, onAuthStateChanged, signInWithEmailAndPassword, signOut,
} from "https://www.gstatic.com/firebasejs/10.14.1/firebase-auth.js";
import {
  getFirestore, collection, doc, getDoc, setDoc, addDoc, updateDoc,
  onSnapshot, query, orderBy, serverTimestamp,
} from "https://www.gstatic.com/firebasejs/10.14.1/firebase-firestore.js";
import { firebaseConfig } from "./firebase-config.js";

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);

const $ = (id) => document.getElementById(id);
const telas = ["tela-login", "tela-negado", "tela-painel"];
function mostrar(id) { telas.forEach((t) => ($(t).hidden = t !== id)); }

let estandes = [];            // [{id, nome, descricao, localizacao, ativo}]
let totais = new Map();       // estandeId -> total de check-ins
let visitantes = new Set();
let unsubs = [];

// ---------- Autenticação ----------
$("form-login").addEventListener("submit", async (e) => {
  e.preventDefault();
  $("login-erro").textContent = "";
  try {
    await signInWithEmailAndPassword(auth, $("login-email").value.trim(), $("login-senha").value);
  } catch (err) {
    $("login-erro").textContent = "E-mail ou senha inválidos.";
    console.error(err);
  }
});
$("btn-sair").onclick = $("btn-sair-negado").onclick = () => signOut(auth);

onAuthStateChanged(auth, async (user) => {
  unsubs.forEach((u) => u());
  unsubs = [];
  if (!user) return mostrar("tela-login");

  // Visitantes anônimos ou usuários sem doc em admins/ não entram no painel.
  let admin = false;
  try { admin = !user.isAnonymous && (await getDoc(doc(db, "admins", user.uid))).exists(); }
  catch (err) { console.error(err); }

  if (!admin) {
    $("uid-negado").textContent = user.uid;
    return mostrar("tela-negado");
  }
  $("usuario").textContent = user.email;
  mostrar("tela-painel");
  iniciarListeners();
});

// ---------- Dados em tempo real ----------
function iniciarListeners() {
  unsubs.push(onSnapshot(query(collection(db, "estandes"), orderBy("nome")), (snap) => {
    estandes = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
    render();
  }, (err) => console.error("estandes", err)));

  // Total por estande calculado a partir dos registros em checkins.
  unsubs.push(onSnapshot(collection(db, "checkins"), (snap) => {
    const novo = new Map();
    const vis = new Set();
    snap.forEach((d) => {
      const { estandeId, visitanteId } = d.data();
      novo.set(estandeId, (novo.get(estandeId) || 0) + 1);
      vis.add(visitanteId);
    });
    const mudou = new Set();
    for (const [k, v] of novo) if (v !== (totais.get(k) || 0)) mudou.add(k);
    totais = novo;
    visitantes = vis;
    render(mudou);
  }, (err) => console.error("checkins", err)));
}

function celula(tag, texto, cls) {
  const el = document.createElement(tag);
  el.textContent = texto ?? "";
  if (cls) el.className = cls;
  return el;
}

function render(destacar = new Set()) {
  const tbody = $("lista");
  tbody.replaceChildren();
  $("vazio").hidden = estandes.length > 0;

  for (const e of estandes) {
    const tr = document.createElement("tr");
    tr.append(celula("td", e.id));

    const tdNome = celula("td", e.nome);
    if (e.descricao) tdNome.append(celula("small", e.descricao));
    tr.append(tdNome, celula("td", e.localizacao));

    const tdEstado = document.createElement("td");
    tdEstado.append(celula("span", e.ativo ? "Ativo" : "Inativo", `tag ${e.ativo ? "on" : "off"}`));
    tr.append(tdEstado);

    tr.append(celula("td", String(totais.get(e.id) || 0), "num" + (destacar.has(e.id) ? " pulsa" : "")));

    const tdAcoes = document.createElement("td");
    const box = celula("div", "", "acoes");
    const bQr = celula("button", "QR code"); bQr.onclick = () => abrirQr(e);
    const bEd = celula("button", "Editar"); bEd.onclick = () => abrirForm(e);
    box.append(bQr, bEd);
    tdAcoes.append(box);
    tr.append(tdAcoes);
    tbody.append(tr);
  }

  let total = 0;
  for (const v of totais.values()) total += v;
  $("kpi-total").textContent = total;
  $("kpi-estandes").textContent = estandes.filter((e) => e.ativo).length;
  $("kpi-visitantes").textContent = visitantes.size;
}

// ---------- Cadastro / edição ----------
let editandoId = null;
$("btn-novo").onclick = () => abrirForm(null);
$("f-cancelar").onclick = () => $("dlg-estande").close();

function abrirForm(e) {
  editandoId = e ? e.id : null;
  $("dlg-titulo").textContent = e ? "Editar estande" : "Novo estande";
  $("f-id").value = e ? e.id : "";
  $("f-id").disabled = !!e;               // o ID é a chave do QR: não muda depois
  $("f-nome").value = e?.nome ?? "";
  $("f-desc").value = e?.descricao ?? "";
  $("f-local").value = e?.localizacao ?? "";
  $("f-ativo").checked = e ? !!e.ativo : true;
  $("f-erro").textContent = "";
  $("dlg-estande").showModal();
}

$("form-estande").addEventListener("submit", async (ev) => {
  ev.preventDefault();
  const dados = {
    nome: $("f-nome").value.trim(),
    descricao: $("f-desc").value.trim(),
    localizacao: $("f-local").value.trim(),
    ativo: $("f-ativo").checked,
  };
  try {
    if (editandoId) {
      await updateDoc(doc(db, "estandes", editandoId), dados);
    } else {
      const idManual = $("f-id").value.trim();
      const payload = { ...dados, criadoEm: serverTimestamp() };
      if (idManual) await setDoc(doc(db, "estandes", idManual), payload);
      else await addDoc(collection(db, "estandes"), payload);
    }
    $("dlg-estande").close();
  } catch (err) {
    $("f-erro").textContent = "Não foi possível salvar: " + err.code;
    console.error(err);
  }
});

$("btn-seed").onclick = async () => {
  const exemplos = [
    ["e01", "Robótica Amazônica", "Robô que mapeia áreas de várzea.", "Entrada, bancada 1"],
    ["e02", "IA para o Açaí", "Classificação de qualidade por imagem.", "Corredor B, bancada 4"],
    ["e03", "Rede Ribeirinha", "Internet comunitária de baixo custo.", "Corredor D, fundo"],
  ];
  try {
    for (const [id, nome, descricao, localizacao] of exemplos) {
      await setDoc(doc(db, "estandes", id), { nome, descricao, localizacao, ativo: true, criadoEm: serverTimestamp() });
    }
  } catch (err) { alert("Erro ao criar exemplos: " + err.code); }
};

// ---------- QR code ----------
function qrSvg(texto) {
  const qr = qrcode(0, "M");
  qr.addData(texto);
  qr.make();
  return qr.createSvgTag({ cellSize: 8, margin: 4, scalable: true });
}
const esc = (s) => String(s).replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
let qrAtual = null;

function abrirQr(e) {
  qrAtual = e;
  $("qr-nome").textContent = e.nome;
  $("qr-id").textContent = e.id;
  $("qr-img").innerHTML = qrSvg(e.id);   // SVG gerado localmente a partir do ID
  $("dlg-qr").showModal();
}
$("qr-fechar").onclick = () => $("dlg-qr").close();

function paginaQr(e) {
  return `<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><title>QR ${esc(e.nome)}</title>
<style>body{font-family:system-ui;text-align:center;margin:2rem}svg{width:min(80vmin,520px);height:auto}code{font-size:1.4rem}</style></head>
<body><h1>${esc(e.nome)}</h1>${qrSvg(e.id)}<p><code>${esc(e.id)}</code></p><p>${esc(e.localizacao || "")}</p></body></html>`;
}
$("qr-abrir").onclick = () => {
  const w = window.open("", "_blank");
  if (w) { w.document.write(paginaQr(qrAtual)); w.document.close(); }
};
$("qr-imprimir").onclick = () => {
  const w = window.open("", "_blank");
  if (w) { w.document.write(paginaQr(qrAtual)); w.document.close(); w.focus(); w.print(); }
};
