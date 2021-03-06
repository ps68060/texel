unit txprocs;
{ 1998-07-02 }

interface

uses

	OTypes,OWindows,txtypes,txcollec;


function InitKeyTab: boolean;
function arcsin(x: TNumber): TNumber;
procedure LGRtoGR(r1: LGRECT; var r2: GRECT);
procedure LGRtoA2(var r: LGRECT);
procedure LA2toGR(var r: LGRECT);
function llrc_intersect(r1: LGRECT; var r2: LGRECT): boolean;
function lrc_intersect(r1: LGRECT; var r2: GRECT): boolean;
function CreatePassCode(pword: string; var pmask: longint): longint;
function CheckPassWord(pword: string; pcode: longint; var pmask: longint): boolean;
procedure ScanFonts(handle,anz: integer; var fcoll: PFontCollection);
procedure ScanConst(const datapath: string; var pcoll: PParameterCollection);


var

	pkt: PKEYT;




implementation

uses

	Strings,Tos,Gem,OProcs,txtypes,txnewvdi;



function InitKeyTab: boolean;

	begin
		InitKeyTab:=false;
		if GetCookie('KEYT',longint(pkt)) then
			if pkt<>nil then
				if pkt^.Magic='KEYT' then
					if pkt^.Size>=40 then InitKeyTab:=true
	end;


function arcsin(x: TNumber): TNumber;

	begin
		if abs(x)<>1.0 then
			begin
				x:=frac(x);
				arcsin:=arctan(x/sqrt(1-sqr(x)))
			end
		else
			if x=1.0 then arcsin:=ev_pihalbe
			else
				arcsin:=-ev_pihalbe
	end;


procedure LGRtoGR(r1: LGRECT; var r2: GRECT);

	begin
		r2.X:=integer(Max(Min(r1.X,32767),-32768));
		r2.Y:=integer(Max(Min(r1.Y,32767),-32768));
		r2.W:=integer(Max(Min(r1.W,32767),-32768));
		r2.H:=integer(Max(Min(r1.H,32767),-32768));
		GRtoA2(r2)
	end;


procedure LGRtoA2(var r: LGRECT);

	begin
		with r do
			begin
				X1:=X;
				Y1:=Y;
				X2:=X+W-1;
				Y2:=Y+H-1
			end
	end;


procedure LA2toGR(var r: LGRECT);

	begin
		with r do
			begin
				X:=X1;
				Y:=Y1;
				W:=X2+1-X;
				H:=Y2+1-Y
			end
	end;


function llrc_intersect(r1: LGRECT; var r2: LGRECT): boolean;
	var x,y,w,h: longint;

	begin
		x:=Max(r2.X,r1.X);
		y:=Max(r2.Y,r1.Y);
		w:=Min(r2.X+r2.W,r1.X+r1.W);
		h:=Min(r2.Y+r2.H,r1.Y+r1.H);
		r2.X:=x;
		r2.Y:=y;
		r2.W:=w-x;
		r2.H:=h-y;
		if (w>x) and (h>y) then
			begin
				LGRtoA2(r2);
				llrc_intersect:=true
			end
		else
			llrc_intersect:=false
	end;


function lrc_intersect(r1: LGRECT; var r2: GRECT): boolean;
	var x,y,w,h: longint;

	begin
		x:=Max(longint(r2.X),r1.X);
		y:=Max(longint(r2.Y),r1.Y);
		w:=Min(longint(r2.X)+longint(r2.W),r1.X+r1.W);
		h:=Min(longint(r2.Y)+longint(r2.H),r1.Y+r1.H);
		r1.X:=x;
		r1.Y:=y;
		r1.W:=w-x;
		r1.H:=h-y;
		LGRtoGR(r1,r2);
		lrc_intersect:=(w>x) and (h>y)
	end;


function CreatePassCode(pword: string; var pmask: longint): longint;
	var q  : integer;
	    ret: longint;

	begin
		pmask:=0;
		CreatePassCode:=0;
		if length(pword)=0 then exit;
		ret:=0;
		for q:=1 to length(pword) do
			begin
				ret:=(((ret shl 6) xor ((ret shr 24) and $000ff000)) xor ord(pword[q]));
				pmask:=(((pmask shl 5) xor ((pmask shr 22) and $0000ff00)) xor ord(pword[q]))
			end;
		CreatePassCode:=ret
	end;


function CheckPassWord(pword: string; pcode: longint; var pmask: longint): boolean;

	begin
		CheckPassWord:=(CreatePassCode(pword,pmask)=pcode)
	end;


procedure ScanFonts(handle,anz: integer; var fcoll: PFontCollection);
	var q,w,asked,
	    got,dval : integer;
	    nfnt     : string;
	    outl     : boolean;
	    fsiz     : array [0..127] of integer;
	    pfnt     : PFont;
	    xfntinfo : XFNT_INFO;

	begin
		BusyMouse;
		new(fcoll,Init(50,50));
		if fcoll<>nil then
			begin
				fcoll^.CaseSensitive:=false;
				if anz>0 then
					for q:=1 to anz do
						begin
							new(pfnt);
							if pfnt<>nil then
								begin
									outl:=vqtName(handle,q,nfnt,pfnt^.Index);
									xfntinfo.size:=sizeof(XFNT_INFO);
									if vqtXFntInfo(handle,pfnt^.Index,1,@xfntinfo) then nfnt:=StrPTrimF(StrPas(xfntinfo.font_name));
									pfnt^.Sizes:=nil;
									if outl then pfnt^.SizeCount:=0
									else
										begin
											pfnt^.SizeCount:=0;
											vst_font(handle,pfnt^.Index);
											asked:=999;
											got:=asked;
											while (got<=asked) and (pfnt^.SizeCount<=127) do
												begin
													asked:=got-1;
													got:=vst_point(handle,asked,dval,dval,dval,dval);
													fsiz[pfnt^.SizeCount]:=got;
													inc(pfnt^.SizeCount)
												end;
											if pfnt^.SizeCount=128 then pfnt^.SizeCount:=0
											else
												begin
													dec(pfnt^.SizeCount);
													getmem(pfnt^.Sizes,pfnt^.SizeCount shl 1);
													if pfnt^.Sizes=nil then pfnt^.SizeCount:=0
													else
														for w:=0 to pfnt^.SizeCount-1 do pfnt^.Sizes^[w]:=fsiz[w]
												end
										end;
									pfnt^.Name:=NewStr('  '+nfnt+' '#0);
									fcoll^.Insert(pfnt)
								end
						end
			end;
		SetSystemFont(handle,q,q,q,q);
		ArrowMouse
	end;


procedure ScanConst(const datapath: string; var pcoll: PParameterCollection);
	label _raus,_weiter;

	var pp         : PParameter;
	    ttxt,cname,
	    ctxt,cdescr: string;
	    buf        : PByteArray;
	    res,w,
	    bufsize    : longint;
	    q,hdl      : integer;

	begin
		new(pcoll,Init(20,10));
		if pcoll=nil then exit;
		pcoll^.Sort:=false;
		buf:=GetMemBuffer(16384,128,bufsize);
		if buf=nil then exit;
		BusyMouse;
		if Exist(datapath+TEXELVAL) then
			begin
				res:=fopen(datapath+TEXELVAL,FO_READ);
				if res<0 then goto _weiter;
				hdl:=integer(res);
				ttxt:='';
				repeat
					res:=fread(hdl,bufsize,buf);
					if res>0 then
						for w:=0 to res-1 do
							if buf^[w]=CR then
								begin
									StrPTrim(ttxt);
									if length(ttxt)>0 then
										if not(ttxt[1] in [';','#']) then
											begin
												new(pp);
												if pp<>nil then
													begin
														cdescr:='';
														q:=pos(' ',ttxt);
														if q>0 then
															begin
																cname:=StrPLeft(ttxt,q-1);
																ttxt:=StrPTrimF(StrPRight(ttxt,length(ttxt)-q));
																q:=pos(' ',ttxt);
																if q>0 then
																	begin
																		ctxt:=StrPLeft(ttxt,q-1);
																		cdescr:=StrPTrimF(StrPRight(ttxt,length(ttxt)-q))
																	end
																else
																	ctxt:=ttxt;
																pp^.Value:=atof(ctxt);
																pp^.Name:=NewStr(cname);
																pp^.ListName:=NewStr('  '+cname+' '#0);
																pp^.Txt:=NewStr(ctxt);
																pp^.Descr:=NewStr(cdescr);
																pp^.Predef:=true;
																if (pp^.Name=nil) or (pp^.Txt=nil) then
																	begin
																		DisposeStr(pp^.Name);
																		DisposeStr(pp^.ListName);
																		DisposeStr(pp^.Txt);
																		DisposeStr(pp^.Descr);
																		dispose(pp)
																	end
																else
																	pcoll^.Insert(pp)
															end
														else
															dispose(pp)
													end
											end;
									ttxt:=''
								end
							else
								if buf^[w]>=32 then ttxt:=ttxt+chr(buf^[w])
				until res<>bufsize;
				fclose(hdl)
			end;
		_weiter:
		if Exist(datapath+TEXELUSRVAL) then
			begin
				res:=fopen(datapath+TEXELUSRVAL,FO_READ);
				if res<0 then goto _raus;
				hdl:=integer(res);
				ttxt:='';
				repeat
					res:=fread(hdl,bufsize,buf);
					if res>0 then
						for w:=0 to res-1 do
							if buf^[w]=CR then
								begin
									StrPTrim(ttxt);
									if length(ttxt)>0 then
										if not(ttxt[1] in [';','#']) then
											begin
												new(pp);
												if pp<>nil then
													begin
														cdescr:='';
														q:=pos(' ',ttxt);
														if q>0 then
															begin
																cname:=StrPLeft(ttxt,q-1);
																ttxt:=StrPTrimF(StrPRight(ttxt,length(ttxt)-q));
																q:=pos(' ',ttxt);
																if q>0 then
																	begin
																		ctxt:=StrPLeft(ttxt,q-1);
																		cdescr:=StrPTrimF(StrPRight(ttxt,length(ttxt)-q))
																	end
																else
																	ctxt:=ttxt;
																pp^.Value:=atof(ctxt);
																pp^.Name:=NewStr(cname);
																pp^.ListName:=NewStr('  '+cname+' '#0);
																pp^.Txt:=NewStr(ctxt);
																pp^.Descr:=NewStr(cdescr);
																pp^.Predef:=true;
																if (pp^.Name=nil) or (pp^.Txt=nil) then
																	begin
																		DisposeStr(pp^.Name);
																		DisposeStr(pp^.ListName);
																		DisposeStr(pp^.Txt);
																		DisposeStr(pp^.Descr);
																		dispose(pp)
																	end
																else
																	pcoll^.Insert(pp)
															end
														else
															dispose(pp)
													end
											end;
									ttxt:=''
								end
							else
								if buf^[w]>=32 then ttxt:=ttxt+chr(buf^[w])
				until res<>bufsize;
				fclose(hdl)
			end;
		_raus:
		freemem(buf,bufsize);
		ArrowMouse
	end;


begin
	pkt:=nil;
end.