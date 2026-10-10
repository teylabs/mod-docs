import os, html, random
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
IDS={'Http':'http','Jobs':'jobs','Models':'mdl','Modules':'mods','Policies':'pol','Providers':'prov','Agents':'agents','Knowledge':'know'}
def busy(layers,mods,versions):   # the timelapse: app's layers and module names, and the API versions in src
    item=lambda pre,x:x if isinstance(x,tuple) else (IDS.get(x,pre+x.lower()),x)   # a name, or (id, name) to follow a folder through renames and moves
    kids=[D(*item('l_',l)) for l in layers]+[D('mods','Modules',*sorted((D(*item('m_',m)) for m in mods),key=lambda n:n[1]))]
    vers=[D(v,v,D('v1c','Controllers'),D('v1r','Resources')) if v=='v1' and len(versions)==1 else D(v,v) for v in versions]
    return [D('app','app',*sorted(kids,key=lambda n:n[1])),D('src','src',D('api','Api',*vers))]
CORE=['Http','Jobs','Models','Policies','Providers']
LAPSE=[   # (layers, modules, API versions) for each step of the timelapse, coming faster and faster
 (CORE,['Agents','Knowledge','Search'],['v1']),
 (CORE,['Agents','Knowledge','Search','Teams'],['v1','v2']),
 (CORE,['Agents','Knowledge','Search','Teams','Workspaces'],['v1','v2','v3']),
 (CORE+['Events','Listeners'],['Agents','Knowledge','Notifications','Search','Teams','Workspaces'],['v1','v2','v3']),
 (CORE+['Events','Listeners','Services'],['Agents','Integrations','Knowledge','Notifications','Search','Teams','Workspaces'],['v1','v2','v3']),
 (CORE+['Events','Listeners','Services'],['Agents','Integrations','Knowledge','Notifications','Search','Teams','Webhooks','Workspaces'],['v1','v2','v3','v4']),
 (CORE+['Enums','Events','Helpers','Listeners','Services'],['Agents','Exports','Integrations','Knowledge','Notifications','Reports','Search','Teams','Webhooks','Workspaces'],['v1','v2','v3','v4']),
 (CORE+['Concerns','Enums','Events','Helpers','Listeners','Observers','Services','Traits'],['Agents','Audit','Exports','Integrations','Knowledge','Notifications','Reports','Search','Sharing','Teams','Webhooks','Workspaces'],['v1','v2','v3','v4','v5']),
 (CORE+['Concerns','Enums','Events','Helpers','Listeners','Managers','Observers','Services','Traits','Utils'],['Admin','Agents','Audit','Exports','Imports','Integrations','Knowledge','Notifications','Onboarding','Reports','Search','Sharing','Teams','Webhooks','Workspaces'],['v1','v2','v3','v4','v5','v6']),
]
# then a burst too fast to follow: every fraction of a second folders arrive, get renamed, move between app and Modules, or go
MORE_LAYERS=['Actions','Casts','Contracts','Data','Exceptions','Facades','Filters','Interfaces','Mail','Pipelines','Repositories','Rules','Scopes','Support','Transformers','ViewModels']
MORE_MODS=['Analytics','Approvals','Archive','Calendar','Comments','Feeds','Files','Glossary','Insights','Labels','Mentions','Permissions','Presence','Publishing','Reminders','Scheduling','Settings','Tags','Templates','Wiki']
RENAMES={'Helpers':'Support','Utils':'Helpers','Managers':'Services','Services':'Actions','Data':'DTOs','Interfaces':'Contracts','Concerns':'Traits','Traits':'Concerns','Wiki':'Docs','Tags':'Labels','Audit':'AuditLog','Admin':'Backoffice','Exports':'Reports','Sharing':'Permissions','Feeds':'Activity','Onboarding':'Setup'}
FIXED={'Http','Jobs','Models','Policies','Providers','Agents','Knowledge'}
rng=random.Random(7)
layers=[(IDS.get(x,'l_'+x.lower()),x) for x in LAPSE[-1][0]]; mods=[(IDS.get(x,'m_'+x.lower()),x) for x in LAPSE[-1][1]]; vers=list(LAPSE[-1][2])
names=lambda:{n for _,n in layers+mods}
for step in range(18):
    for _ in range(rng.randint(2,3)):
        op=rng.choices(['add','rename','move','delete'],[4,3,2,2])[0]
        loose=[(lst,x) for lst in (layers,mods) for x in lst if x[1] not in FIXED]
        if op=='add':
            pool,into,pre=(MORE_MODS,mods,'m_') if rng.random()<0.6 else (MORE_LAYERS,layers,'l_')
            left=[x for x in pool if x not in names()]
            if left: n=rng.choice(left); into.append((pre+n.lower(),n))
        elif op=='rename':
            can=[(lst,x) for lst,x in loose if RENAMES.get(x[1]) and RENAMES[x[1]] not in names()]
            if can: lst,x=rng.choice(can); lst[lst.index(x)]=(x[0],RENAMES[x[1]])
        elif op=='move':   # a layer becomes a module, or a module turns back into a layer
            if loose: lst,x=rng.choice(loose); lst.remove(x); (mods if lst is layers else layers).append(x)
        elif loose:
            lst,x=rng.choice(loose); lst.remove(x)
    if step%5==4: vers.append(f'v{len(vers)+1}')
    LAPSE.append((sorted(layers,key=lambda x:x[1]),list(mods),list(vers)))
STAGES=[
 [D('app','app',http(),models(),prov)],
 [D('app','app',http(F('docctl','DocumentController.php')),models(F('doc','Document.php')),prov)],
 [D('app','app',D('act','Actions',F('index','SummarizeDocument.php')),http(F('docctl','DocumentController.php')),models(F('doc','Document.php')),prov)],
 [D('app','app',D('act','Actions',F('index','SummarizeDocument.php')),http(F('docctl','DocumentController.php')),models(F('doc','Document.php')),D('mods','Modules',agents),prov)],
 [final_app],
 [limit(final_app,3), D('src','src',D('api','Api',D('v1','v1',D('v1c','Controllers'),D('v1r','Resources'))))],
]+[busy(*step) for step in LAPSE]
NS=len(STAGES)
STAGES.append([F('flat','index.php')])   # the easter egg: everything collapses into one index.php before the loop restarts
FIRST=1.0; SLIDE=0.8; HOLD=0.1; GAG=2.2
GAPS=[1.2]*5+[1.2,1.05,0.9,0.78,0.67,0.58,0.5,0.45,0.42]+[round(max(0.1,0.38*0.82**k),2) for k in range(17)]   # time on each stage before the next: steady, then a timelapse
SEQ=list(range(NS))+[NS,0]   # stage shown in each segment of the loop
T=[0.0]; DUR=[0.0]                              # when each segment's transition starts, and how long it takes
for i in range(1,len(SEQ)):
    T.append(FIRST if i==1 else T[-1]+GAPS[i-2] if i<NS else T[NS-1]+HOLD if i==NS else T[NS]+GAG)
for i in range(1,len(SEQ)):   # motion eases off as the pace picks up, until changes simply snap in
    pace=min(T[i+1]-T[i] if i+1<len(SEQ) else SLIDE*2, T[i]-T[i-1] if 1<i<=NS else SLIDE*2)
    DUR.append(SLIDE if i>=NS else 0.02 if pace<0.6 else round(min(SLIDE,pace*0.5),2))   # the collapse and unfold always slide
CYCLE=round(T[-1]+DUR[-1]+0.2,1)
pc=lambda sec:round(sec/CYCLE*100,2)
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
        rows[root[0]]=(r[0],'',root[1],root[2] is not None); r[0]+=1
        rec(root,'')
    return rows,counts
R=[render(t) for t in STAGES]   # index 0..NS-1
ids=[]
for rows,_ in R:
    for k in rows:
        if k not in ids: ids.append(k)
maxrows=22   # the terminal's height in rows; the timelapse overflows it
W=600; H=TOP+maxrows*LH+8
esc=lambda s:html.escape(s,quote=False)
def build(name,t):
    css=[f"text{{font-family:ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;font-size:{FS}px;fill:{t['text']};white-space:pre}}",
         f".d{{font-weight:700;fill:{t['dir']}}}.m,.p{{fill:{t['muted']}}}"]
    body=[]
    def depth(pre): return pre.count('    ')+pre.count('│   ')
    def steps(windows):   # opacity windows (seconds) as step-end keyframes
        kf={0.0:0}
        for st,en in windows:
            kf[pc(st)]=1
            if en<CYCLE: kf[pc(en)]=0
        return ''.join(f"{p}%{{opacity:{v}}}" for p,v in sorted(kf.items()))+('' if 100 in kf else f"100%{{opacity:{kf[max(kf)]}}}")
    for idx,nid in enumerate(ids):
        state=[R[k][0].get(nid) for k in SEQ]
        y=lambda i:state[i][0]*LH
        fr=[(0.0,1 if state[0] else 0,y(0) if state[0] else 0)]
        for i in range(1,len(SEQ)):
            a,b,t0,d=state[i-1],state[i],T[i],DUR[i]
            if a and b:
                fr+= [(t0,1,y(i-1)),(t0+d,1,y(i))]
            elif b:   # appears: slide out from the row above it, fading in straight away
                order=sorted(R[SEQ[i]][0],key=lambda n:R[SEQ[i]][0][n][0])
                above=[n for n in order[:order.index(nid)] if n in R[SEQ[i-1]][0]]
                start=R[SEQ[i-1]][0][above[-1]][0]*LH if above else 0
                fr+= [(t0,0,start),(t0+d,1,y(i))]
            elif a:   # disappears: slide up into its parent if the parent stays, else fade in place
                par=PARENT.get(nid)
                into=R[SEQ[i]][0][par][0]*LH if par in R[SEQ[i]][0] else None
                if into is None:   # nothing it belonged to survives: fold into the top row
                    anc=nid
                    while anc in PARENT and anc not in R[SEQ[i]][0]: anc=PARENT[anc]
                    if anc not in R[SEQ[i]][0]: into=0
                fr+= [(t0,1,y(i-1)),(t0+d,0,into)] if into is not None else [(t0,1,y(i-1)),(t0+d*0.5,0,y(i-1))]
        fr.append((CYCLE,fr[0][1],fr[0][2]))
        css.append(f".n{idx}{{animation:a{idx} {CYCLE}s infinite ease-in-out}}@keyframes a{idx}{{"+''.join(f"{pc(t0)}%{{opacity:{o};transform:translateY({yy}px)}}" for t0,o,yy in fr)+"}")
        # one text per look of the row (its prefix, or a highlight), shown while that look applies
        looks={}
        pres=[i for i in range(len(SEQ)) if state[i]]
        for i in pres:
            new=i>0 and not state[i-1]
            st=T[i] if (i==0 or new) else T[i]+DUR[i]
            nxt=i+1
            en=T[nxt]+DUR[nxt] if nxt<len(SEQ) else CYCLE
            hl=0<i<=NS and (new or depth(state[i-1][1])!=depth(state[i][1]) or state[i-1][2]!=state[i][2])
            key=(state[i][1],state[i][2],i if hl else None)
            looks.setdefault(key,[]).append((st,en,i))
        parts=[]
        for (pre,_,hli),wins in looks.items():
            vc=f"v{idx}_{len(parts)}"
            css.append(f".{vc}{{animation:k{vc} {CYCLE}s infinite step-end}}@keyframes k{vc}{{{steps([(st,en) for st,en,_ in wins])}}}")
            nm=state[wins[0][2]][2]; isdir=state[wins[0][2]][3]
            cls='d' if isdir else ''
            if hli is not None:
                base=t['dir'] if isdir else t['text']; hc=f"h{idx}_{hli}"; fade=T[hli+1] if hli+1<len(SEQ) else CYCLE; g=fade-T[hli]
                css.append(f".{hc}{{animation:k{hc} {CYCLE}s infinite}}@keyframes k{hc}{{0%,{pc(fade-min(1.0,g*0.3))}%{{fill:{t['accent']}}}{pc(fade+min(0.3,g*0.1))}%,100%{{fill:{base}}}}}")
                cls+=' '+hc
            parts.append(f'<text class="{vc}" x="{PADX}" y="{TOP}"><tspan class="p">{esc(pre)}</tspan><tspan class="{cls.strip()}">{esc(nm)}</tspan></text>')
        body.append(f'<g class="n{idx}">'+''.join(parts)+'</g>')
    dots=''.join(f'<circle cx="{22+i*18}" cy="20" r="6" fill="{c}"/>' for i,c in enumerate(t['dots']))
    svg=(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}" role="img" aria-label="A terminal watching a Laravel app grow from laravel new: documents in the default folders, an Actions folder, an Agents module, the knowledge code moving into its own module, then a versioned API in src beside app, more modules and app layers as the app grows, then a timelapse of ever more modules, layers and API versions until the tree overflows the terminal, before it all collapses into a single index.php and starts again">'
         f'<style>{"".join(css)}</style>'
         f'<rect x="0.5" y="0.5" width="{W-1}" height="{H-1}" rx="10" fill="{t["win"]}" stroke="{t["border"]}"/>'
         f'<path d="M0.5 {HEAD} V10.5 a10 10 0 0 1 10 -10 H{W-10.5} a10 10 0 0 1 10 10 V{HEAD} Z" fill="{t["bar"]}"/>'
         f'<line x1="0.5" y1="{HEAD}" x2="{W-0.5}" y2="{HEAD}" stroke="{t["border"]}"/>{dots}'
         f'<text class="m" x="{W/2}" y="25" text-anchor="middle" style="font-size:12.5px">~/knowledge-base</text>'
         +f'<clipPath id="screen"><rect x="1" y="{HEAD+1}" width="{W-2}" height="{H-HEAD-6}"/></clipPath><g clip-path="url(#screen)">'+''.join(body)+'</g></svg>')
    open(os.path.join(OUT,f'evolve-{name}.svg'),'w').write(svg)
for n,t in THEMES.items(): build(n,t)
for k,(rows,c) in enumerate(R): print('stage',k+1,len(rows),'rows',c)
print('ok',W,H)
