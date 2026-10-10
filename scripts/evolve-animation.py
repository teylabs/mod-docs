import os, html
# Generates docs/public/evolve-{light,dark}.svg, the README animation of a Laravel app growing
# (a terminal running `watch tree`). Run: python3 scripts/evolve-animation.py
OUT=os.path.join(os.path.dirname(os.path.abspath(__file__)),'..','docs','public')
THEMES={
 'light':dict(win='#FBF8F3',bar='#EFE9DF',border='#DDD3C4',text='#3E2D24',dir='#7A4B30',muted='#8A7A6C',accent='#B65326',dots=('#E0675C','#E4B34A','#6DBA5A')),
 'dark': dict(win='#0F1218',bar='#1A1F27',border='#2B323C',text='#D9D0C1',dir='#DCC3A0',muted='#7D8590',accent='#E8834F',dots=('#E0675C','#E4B34A','#6DBA5A')),
}
D=lambda id,name,*kids:(id,name,list(kids))   # directory
F=lambda id,name:(id,name,None)                # file
ROOT_SHARED=[D('ctl','Controllers',F('base','Controller.php'))]
def http(*extra): return D('http','Http',D('ctl','Controllers',F('base','Controller.php'),*extra))
def models(*extra): return D('mdl','Models',*sorted([F('user','User.php'),*extra],key=lambda n:n[1]))
prov=D('prov','Providers',F('asp','AppServiceProvider.php'))
agents=D('agents','Agents',D('ag_act','Actions',F('answer','AnswerQuestion.php')),D('ag_mdl','Models',F('conv','Conversation.php')))
def limit(n,depth,dirs=True):
    if n[2] is None: return n
    if depth==0: return (n[0],n[1],[])
    return (n[0],n[1],[limit(c,depth-1,dirs) for c in n[2] if not (dirs and c[2] is None)])
final_app=D('app','app',http(),models(),D('mods','Modules',agents,D('know','Knowledge',D('k_act','Actions',F('index2','SummarizeDocument.php')),D('k_http','Http',D('k_ctl','Controllers',F('docctl2','DocumentController.php'))),D('k_mdl','Models',F('doc2','Document.php')))),prov)
grown=D('app','app',D('http','Http'),D('jobs','Jobs'),D('mdl','Models'),D('mods','Modules',D('agents','Agents'),D('know','Knowledge'),D('search','Search'),D('teams','Teams')),D('pol','Policies'),D('prov','Providers'))
STAGES=[
 [D('app','app',http(),models(),prov)],
 [D('app','app',http(F('docctl','DocumentController.php')),models(F('doc','Document.php')),prov)],
 [D('app','app',D('act','Actions',F('index','SummarizeDocument.php')),http(F('docctl','DocumentController.php')),models(F('doc','Document.php')),prov)],
 [D('app','app',D('act','Actions',F('index','SummarizeDocument.php')),http(F('docctl','DocumentController.php')),models(F('doc','Document.php')),D('mods','Modules',agents),prov)],
 [final_app],
 [limit(final_app,3), D('src','src',D('api','Api',D('v1','v1',D('v1c','Controllers'),D('v1r','Resources'))))],
 [grown, D('src','src',D('api','Api',D('v1','v1',D('v1c','Controllers'),D('v1r','Resources'))))],
 [grown, D('src','src',D('api','Api',D('v1','v1'),D('v2','v2',D('v2c','Controllers'),D('v2r','Resources'))))],
 [grown, D('src','src',D('api','Api',D('v1','v1'),D('v2','v2'),D('v3','v3',D('v3c','Controllers'),D('v3r','Resources'))))],
]
HEADERS=['tree app']*5+['tree -d -L 3 app src']*4
NS=len(STAGES); CYCLE=46
START={k:round(2+(k-1)*10.5,1) for k in range(1,NS+1)}; END=97
LH=22; FS=14.5; PADX=24; HEAD=40; TOP=HEAD+28+round(LH*0.4)
PARENT={}
def render(roots):
    rows={}; counts=[0,0]
    r=[0]
    def rec(n,prefix):
        kids=n[2] or []
        for i,c in enumerate(kids):
            last=i==len(kids)-1
            rows[c[0]]=(r[0],prefix+('└── ' if last else '├── '),c[1],c[2] is not None)
            PARENT.setdefault(c[0],n[0])
            r[0]+=1; counts[0 if c[2] is not None else 1]+=1
            rec(c,prefix+('    ' if last else '│   '))
    for root in roots:
        rows[root[0]]=(r[0],'',root[1],True); r[0]+=1
        rec(root,'')
    return rows,counts
R=[render(t) for t in STAGES]   # index 0..NS-1
ids=[]
for rows,_ in R:
    for k in rows:
        if k not in ids: ids.append(k)
maxrows=max(len(r[0]) for r in R)
W=600; H=TOP+maxrows*LH+44
esc=lambda s:html.escape(s,quote=False)
def build(name,t):
    css=[f"text{{font-family:ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;font-size:{FS}px;fill:{t['text']};white-space:pre}}",
         f".d{{font-weight:700;fill:{t['dir']}}}.m,.p{{fill:{t['muted']}}}"]
    body=[]
    for idx,nid in enumerate(ids):
        present=[k for k in range(NS) if nid in R[k][0]]
        # base row = row in last present stage
        anchor=present[-1]; arow=R[anchor][0][nid][0]
        y=TOP+arow*LH
        fr=[]
        def dy(k): return (R[k][0][nid][0]-arow)*LH
        first=present[0]
        a=START[first+1]
        fa = a+3 if first>0 else a
        fr.append(f"0%,{fa-0.01:.2f}%{{opacity:0;transform:translateY({dy(first)}px)}}")
        fr.append(f"{fa+2.5:.1f}%{{opacity:1;transform:translateY({dy(first)}px)}}")
        prev=first
        for k in present[1:]:
            b=START[k+1]
            fr.append(f"{b:.1f}%{{opacity:1;transform:translateY({dy(prev)}px)}}")
            fr.append(f"{b+3:.1f}%{{opacity:1;transform:translateY({dy(k)}px)}}")
            prev=k
        last=present[-1]
        if last<NS-1:  # disappears
            b=START[last+2]
            par=PARENT.get(nid)
            if par is not None and par in R[last+1][0]:
                # collapse: slide up into the parent while fading
                up=(R[last+1][0][par][0]-arow)*LH
                fr.append(f"{b:.1f}%{{opacity:1;transform:translateY({dy(last)}px)}}")
                fr.append(f"{b+2.6:.1f}%,100%{{opacity:0;transform:translateY({up}px)}}")
            else:
                fr.append(f"{b-0.6:.1f}%{{opacity:1;transform:translateY({dy(last)}px)}}")
                fr.append(f"{b+0.4:.1f}%,100%{{opacity:0;transform:translateY({dy(last)}px)}}")
        else:
            fr.append(f"{END}%{{opacity:1;transform:translateY(0px)}}")
            fr.append(f"100%{{opacity:0;transform:translateY(0px)}}")
        css.append(f".n{idx}{{animation:a{idx} {CYCLE}s infinite ease-in-out}}@keyframes a{idx}{{{''.join(fr)}}}")
        parts=[]
        for k in present:
            row,pre,nm,isdir=R[k][0][nid]
            b=START[k+1]+(3 if k>0 else 0); e=(START[k+2]+3) if k+1<NS else 101
            # highlight if new or moved at this stage
            moved = k>0 and (nid not in R[k-1][0] or R[k-1][0][nid][1].count('    ')+R[k-1][0][nid][1].count('│   ')!=pre.count('    ')+pre.count('│   '))
            cls=('d' if isdir else '')+(' hl' if moved and k>0 else '')
            if b<=2 and e>=101: kf="0%,100%{opacity:1}"
            elif b<=2: kf=f"0%,{e-0.01:.2f}%{{opacity:1}}{e}%,100%{{opacity:0}}"
            elif e>=101: kf=f"0%,{b-0.01:.2f}%{{opacity:0}}{b:.2f}%,100%{{opacity:1}}"
            else: kf=f"0%,{b-0.01:.2f}%{{opacity:0}}{b:.2f}%,{e-0.01:.2f}%{{opacity:1}}{e}%,100%{{opacity:0}}"
            vc=f"v{idx}_{k}"
            css.append(f".{vc}{{animation:k{vc} {CYCLE}s infinite step-end}}@keyframes k{vc}{{{kf}}}")
            hl=''
            if 'hl' in cls:
                base=t['dir'] if isdir else t['text']
                hc=f"h{idx}_{k}"
                css.append(f".{hc}{{animation:k{hc} {CYCLE}s infinite}}@keyframes k{hc}{{0%,{b+3}%{{fill:{t['accent']}}}{min(e,99)-2}%{{fill:{t['accent']}}}{min(e,99)+1}%,100%{{fill:{base}}}}}")
                hl=' '+hc
            ncls=('d' if isdir else '')+hl
            parts.append(f'<text class="{vc}" x="{PADX}" y="{y}"><tspan class="p">{esc(pre)}</tspan><tspan class="{ncls.strip()}">{esc(nm)}</tspan></text>')
        body.append(f'<g class="n{idx}">'+''.join(parts)+'</g>')
    for k in range(NS):
        d,f=R[k][1]; rows=len(R[k][0])
        b=START[k+1]+(3 if k>0 else 0); e=(START[k+2]+3) if k+1<NS else END
        yy=TOP+rows*LH+LH*0.9
        out=(START[k+2]-0.6) if k+1<NS else END
        if k==0: kf=f"0%,{out:.2f}%{{opacity:1}}{out+0.8:.2f}%,100%{{opacity:0}}"
        else: kf=f"0%,{b:.2f}%{{opacity:0}}{b+1:.2f}%,{out:.2f}%{{opacity:1}}{out+0.8:.2f}%,100%{{opacity:0}}"
        css.append(f".s{k}{{animation:sm{k} {CYCLE}s infinite linear}}@keyframes sm{k}{{{kf}}}")
        summ=f'{d} directories' if '-d' in HEADERS[k] else f'{d} directories, {f} files'
        body.append(f'<text class="m s{k}" x="{PADX}" y="{yy:.0f}">{summ}</text>')
    dots=''.join(f'<circle cx="{22+i*18}" cy="20" r="6" fill="{c}"/>' for i,c in enumerate(t['dots']))
    svg=(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}" role="img" aria-label="A terminal watching a Laravel app grow from laravel new: documents in the default folders, an Actions folder, an Agents module, the knowledge code moving into its own module, then a versioned API in src beside app, more modules and app layers as the app grows, and later v2 and v3 of the API">'
         f'<style>{"".join(css)}</style>'
         f'<rect x="0.5" y="0.5" width="{W-1}" height="{H-1}" rx="10" fill="{t["win"]}" stroke="{t["border"]}"/>'
         f'<path d="M0.5 {HEAD} V10.5 a10 10 0 0 1 10 -10 H{W-10.5} a10 10 0 0 1 10 10 V{HEAD} Z" fill="{t["bar"]}"/>'
         f'<line x1="0.5" y1="{HEAD}" x2="{W-0.5}" y2="{HEAD}" stroke="{t["border"]}"/>{dots}'
         f'<text class="m" x="{W/2}" y="25" text-anchor="middle" style="font-size:12.5px">~/knowledge-base</text>'
         +''.join(body)+'</svg>')
    open(os.path.join(OUT,f'evolve-{name}.svg'),'w').write(svg)
for n,t in THEMES.items(): build(n,t)
for k,(rows,c) in enumerate(R): print('stage',k+1,len(rows),'rows',c)
print('ok',W,H)
