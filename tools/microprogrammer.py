from Tkinter import *
import ttk
master = Tk()

def to_hex(element):
	temp=str(hex(element)).split("0x")[1]
	if len(temp)==1:
		return "0"+temp
	else:
		return temp


#variables
ALU = StringVar(master)
ALU.set("ALU")

TB = StringVar(master)
TB.set("TB")

FB = StringVar(master)
FB.set("FB")

S = StringVar(master)
S.set("S")

P = StringVar(master)
P.set("P")

LC = StringVar(master)
LC.set("LC")

SEQ = StringVar(master)
SEQ.set("SEQ")

ADR = StringVar(master)
ADR.set("ADR")

alu_options=["NOP","AR:=buss", "AR=BUSS'", "AR=0","AR=AR+BUSS","AR=AR-BUSS","AR=AR and BUSS","AR=AR or BUSS","AR=AR<<1","AR=AR>>1","COMB"]
a = apply(OptionMenu, (master, ALU) + tuple(alu_options))
a.pack(side=LEFT)

tb_options=["NOP","IR","PM","PC","GRx","ADR","AR","IN"]
a = apply(OptionMenu, (master, TB) + tuple(tb_options))
a.pack(side=LEFT)

fb_options=["NOP","IR","PM","PC","GRx","ASR","OUT","GM"]
a = apply(OptionMenu, (master, FB) + tuple(fb_options))
a.pack(side=LEFT)

s_options=["GRx controls mux","M controls mux"]
a = apply(OptionMenu, (master, S) + tuple(s_options))
a.pack(side=LEFT)

p_options=["PC=PC","PC=PC+1"]
a = apply(OptionMenu, (master, P) + tuple(p_options))
a.pack(side=LEFT)

lc_options=["NOP","down 1","8 least sig. from bus",]
a = apply(OptionMenu, (master, LC) + tuple(lc_options))
a.pack(side=LEFT)

seq_options=["up 1","load from k1","load from k2","zero","jmp to uADDR om z=0,uPC+1 otherwise","jump to uADR"]
a = apply(OptionMenu, (master, SEQ) + tuple(seq_options))
a.pack(side=LEFT)

adresses=[to_hex(x) for x in range(256)]

a = ttk.Combobox(master, textvariable=ADR, values=adresses)
a.pack(side=LEFT)


def ok():
	temp=0
	if ALU.get() in alu_options:	
		temp+= alu_options.index(ALU.get())<<22
	if TB.get() in tb_options:
		temp+= tb_options.index(TB.get())<<19
	if FB.get() in fb_options:	
		temp+= fb_options.index(FB.get())<<16
	if S.get() in s_options:
		temp+= s_options.index(S.get())<<15
	if P.get() in p_options:	
		temp+= p_options.index(P.get())<<14
	if LC.get() in lc_options:
		temp+= lc_options.index(TC.get())<<12
	if SEQ.get() in seq_options:
		temp+= seq_options.index(SEQ.get())<<8
	if ADR.get() in adresses:
		temp+= adresses.index(ADR.get())

    	print(hex(temp))
	ALU.set("ALU")
	TB.set("TB")
	FB.set("FB")
	S.set("S")
	P.set("P")
	LC.set("LC")
	SEQ.set("SEQ")


button = Button(master, text="OK", command=ok)
button.pack(side=BOTTOM)

mainloop()

