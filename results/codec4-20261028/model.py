import numpy as np, sys
for f in sys.argv[1:]:
 w,h=map(int,f[:-4].split('_')[-1].split('x')); raw=np.fromfile(f,'<u2').reshape(h,w).astype(np.int32)
 totals=None
 for py in range(2):
  for px in range(2):
   p=raw[py::2,px::2]; a=p[2:-2,2:-2]; L=p[2:-2,1:-3]; U=p[1:-3,2:-2]; UL=p[1:-3,1:-3]; UR=p[1:-3,3:-1]
   preds=[(L+U+UL+UR+2)//4,np.clip(L+U-UL,np.minimum(L,U),np.maximum(L,U)),(L+U+1)//2,(2*L+U+UR+2)//4]
   for n in [2,3,4]:
    s=np.zeros_like(a)
    for dy in range(1,n+1):
     # limit available to 2 rows
     if dy>2:continue
     for dx in [-2,-1,0,1,2]:s+=p[2-dy:h//2-2-dy,2+dx:w//2-2+dx]
    s+=L
    preds.append((s+(min(n,2)*5+1)//2)//(min(n,2)*5+1))
   costs=[]
   for pred in preds:
    e=a-pred;u=np.where(e<0,-2*e-1,2*e); hh,ww=u.shape; hh=hh//64*64;ww=ww//64*64;u=u[:hh,:ww].reshape(hh//64,64,ww//64,4,16)
    best=np.full(u.shape[:-1],1e9)
    for k in range(12):best=np.minimum(best,(u>>k).sum(-1)+16*(k+1)+4)
    costs.append(best.sum((1,3)))
   t=np.stack(costs);totals=t if totals is None else totals+t
 print(f, 'rice bpp', totals.sum((1,2))/(hh*ww*4),'tile best', totals.min(0).sum()/(hh*ww*4),flush=True)
