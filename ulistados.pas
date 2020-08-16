unit ulistados;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SQLDB, crt,
  SQLite3Conn, DateUtils,funciones;
type

  TRApunte = record
    id: integer;
    fecha: TDatetime;
    texto: string;
  end;

procedure compruebaCarpeta;
function openDb(const dbName: string): boolean;
function sqlDBError(const msg: string): string;
procedure creaTabla;
procedure cargaTodos;
procedure cargaHoy;
procedure cargaAyer;
procedure cargaFecha(f:String);
procedure cargaRango(fi:String; ff: String);
procedure dibujaTabla(titulo: string; para: string);
procedure dibujaRango(fi: string; ff: string ; tit:String);
procedure cierraDb;
procedure grabaApunte(texto:String);
procedure pideFechaYGraba;
procedure borraId(id: integer);
function buscaApuntePorId(id: integer): TRApunte;
procedure buscaId;
procedure actualizaId(id: integer);
procedure borraFecha(f:String);
procedure borraRango(fi:String; ff: String);
procedure buscaTexto(tt:String);
procedure dibujaLikes(titulo: string; para: string);
var
  sqlite3: TSQLite3Connection;
  dbTrans: TSQLTransaction;
  dbQuery: TSQLQuery;
  slNames: TStringList;
  estado: boolean;
  sql: string;
  parametro, tituloFecha: string;
  fs: TFormatSettings;
  fsInverso: TFormatSettings;
   hayApuntes:boolean;
implementation



procedure compruebaCarpeta;
var
  pathToData: string;
begin
  pathToData := GetUserDir() + '.Apuntes';
  if DirectoryExists(pathToData) then
  begin
    openDb(pathToData + '/datos.db');
  end

  else
  begin
    writeln('NO existe directorio de datos');
    writeln('Creándolo');
    MkDir(pathToData);
    openDb(pathToData + '/datos.db');

  end;
end;

function openDb(const dbName: string): boolean;

begin
  // create components
  sqlite3 := TSQLite3Connection.Create(nil);
  dbTrans := TSQLTransaction.Create(nil);
  dbQuery := TSQLQuery.Create(nil);
  slNames := TStringList.Create;

  // setup components
  sqlite3.Transaction := dbTrans;
  dbTrans.Database := sqlite3;
  dbQuery.Transaction := dbTrans;
  dbQuery.Database := sqlite3;
  slNames.CaseSensitive := False;
  sqlite3.DatabaseName := dbName;
  sqlite3.CharSet := 'UTF8';

  if FileExists(dbName) then
    try
      sqlite3.Open;
      Result := sqlite3.Connected;
      sqlite3.GetTableNames(slNames, False);

      if slNames.Count > 0 then
      begin

        estado := True;

      end

    except
      on E: Exception do
      begin
        sqlite3.Close;
        writeln(sqlDBError(E.Message));
      end;
    end
  else
  begin
    writeln('Archivo de datos no existe. Creando...');
    sqlite3.CreateDB;
    creaTabla();

  end;
end;

function sqlDBError(const msg: string): string;
begin

  Result := 'ERROR: ' + StringReplace(msg, 'TSQLite3Connection : ', '', []);
end;

procedure creaTabla;
var
  sql: string;

begin

  try
    sql := 'CREATE TABLE  "apuntes" ("ID" Integer NOT NULL PRIMARY KEY AUTOINCREMENT, "FECHA" DATETIME NOT NULL, "TEXTO" TEXT NOT NULL) ;';
    sqlite3.Open;  // Abrimos la conexión
    dbTrans.Active := True; // Establecemos activa la transacción.

    sqlite3.ExecuteDirect(sql);
    dbTrans.Commit;

  except
    on E: Exception do
    begin
      sqlite3.Close;
      writeln(sqlDBError(E.Message));
    end;
  end;
end;

procedure cargaTodos;
begin
     ClrScr;
  tituloFecha := 'Todos los apuntes';
  writeln();
  TextColor(Yellow);
  writeln('╔═══════════════════╗');
  writeln('║ ', tituloFecha, ' ║');
  writeln('╚═══════════════════╝');
  TextColor(White);
  writeln();
  sql := 'select * from apuntes order by fecha;';
  dbQuery.sql.Clear;
  dbQuery.sql.add(sql);
  dbQuery.Open;
  while not dbQuery.EOF do
  begin
    Writeln(' ', format('%5d', [dbQuery.FieldByName('ID').AsInteger])
      , ' ┤ ', FormatDateTime('dd-MM-yyyy  hh:nn', dbQuery.FieldByName('fecha').AsDateTime), ' ├ ', dbQuery.FieldByName('texto').AsString);
    dbQuery.Next;
  end;
  cierraDb;
  writeln;

end;

procedure cargaHoy;
begin

  parametro := datetoStr(Date, fsInverso);
  tituloFecha := datetoStr(Date, fs);
  dibujaTabla(tituloFecha, parametro);
end;

procedure cargaAyer;
begin
  parametro := FormatDateTime('yyyy-MM-dd', Yesterday);
  tituloFecha := datetoStr(Yesterday, fs);
  dibujaTabla(tituloFecha, parametro);

end;

procedure borraFecha(f:String);
var ef:TEsFecha;
  resp,mensaje: String;
 begin
   hayApuntes:=false;
      fs.ShortDateFormat := 'dd-MM-yyyy';
      ef:= esFecha(f);
      if ef.esFecha  then
      begin
        dibujaTabla('borrar '+FormatDateTime('dd-MM-yyyy', ef.fecha),FormatDateTime('yyyy-MM-dd', ef.fecha));
        if hayApuntes = false then
        begin
             exit;
          end;

         textColor(Yellow);


      Write('  ¿Borrar los apuntes listados' + '? [S/N] ');
      TextColor(White);
      readln(resp);
      textColor(Yellow);
      if ((resp = 'S') or (resp = 's')) then
       begin
         parametro := FormatDateTime('yyyy-MM-dd', ef.fecha);
         dbQuery.sql.Clear;
         dbQuery.sql.add('DELETE FROM apuntes WHERE substr(fecha, 1, 10) = "' + parametro + '";');
         dbQuery.ExecSQL;
         dbTrans.Commit;
         mensaje:=   ' apuntes borrados';
         if  dbQuery.RowsAffected=1 then  mensaje:=   ' apunte borrado';
         writeln(dbQuery.RowsAffected,mensaje);
         writeln;
       end;

      end else
      begin
        TextBackground(white);
        textColor(Red);
          writeln(f,'   NO ES UNA FECHA VÁLIDA ');
          textColor(White);
          TextBackground(black);
          writeln(' Formato: [dia], [dia-mes],  [dia-mes-año] (dia de 1 a 31)  (mes de 1 a 12) ');
          writeln;
      end;
 end;

procedure borraRango(fi: String; ff: String);
var efi:TEsFecha;
   eff:TEsFecha;
   parametro2,resp, mensaje : String;
begin
   hayApuntes:=false;
  efi:= esFecha(fi);
   if efi.esFecha then
      begin
        textColor(White);
        writeln(' FECHA INICIAL ',DatetoStr(efi.fecha));
      end else
      begin
          TextBackground(white);
          textColor(Red);
          writeln(fi,'   NO ES UNA FECHA VÁLIDA ');
          textColor(White);
          TextBackground(black);
          writeln(' Formato: [dia], [dia-mes],  [dia-mes-año] (dia de 1 a 31)  (mes de 1 a 12) ');
          writeln;
          Exit;
      end;
      eff:= esFecha(ff);
      if eff.esFecha  then
      begin
        textColor(White);
        writeln(' FECHA FINAL ',DatetoStr(eff.fecha));
      end else
      begin
          TextBackground(white);
           textColor(Red);
           writeln(ff,'   NO ES UNA FECHA VÁLIDA ');
             textColor(White);
             TextBackground(black);
           writeln(' Formato: [dia], [dia-mes],  [dia-mes-año] (dia de 1 a 31)  (mes de 1 a 12) ');
           writeln;
            Exit;
      end;
          parametro  := FormatDateTime('yyyy-MM-dd', efi.fecha);
          parametro2 := FormatDateTime('yyyy-MM-dd', eff.fecha);


      dibujaRango(parametro,parametro2, 'Borrar de '+FormatDateTime('dd-MM-yyyy', efi.fecha)+' a '+FormatDateTime('dd-MM-yyyy', eff.fecha));
      if hayApuntes= false then exit;

         textColor(Yellow);


      Write('  ¿Borrar los apuntes listados' + '? [S/N] ');
      TextColor(White);
      readln(resp);
      textColor(Yellow);
            if ((resp = 'S') or (resp = 's')) then
       begin
         dbQuery.sql.Clear;
         dbQuery.sql.add('DELETE FROM apuntes WHERE substr(fecha, 1, 10)  BETWEEN "'+parametro+'" and "'+parametro2+'" ;');
         dbQuery.ExecSQL;
         dbTrans.Commit;
         mensaje:=   ' apuntes borrados';
         if  dbQuery.RowsAffected=1 then  mensaje:=   ' apunte borrado';
         writeln(dbQuery.RowsAffected,mensaje);
         writeln;
       end;


end;

procedure buscaTexto(tt:String);
var
f:String;
begin
  if tt<>'' then
  begin
    f:= tt;
  end else
  begin
     textColor(White);
    Write('Texto a buscar: ');
    readln(f);
  end;

    dibujaLikes('Resultado de buscar: '+f,f);
end;

procedure cargaFecha(f: String);
var ef:TEsFecha;
begin
   fs.ShortDateFormat := 'dd-MM-yyyy';
  ef:= esFecha(f);
   if ef.esFecha  then
      begin
        textColor(White);
         parametro := FormatDateTime('yyyy-MM-dd', ef.fecha);
       dibujaTabla(DateToStr(ef.fecha,fs),parametro);
      end else
      begin
        TextBackground(white);
        textColor(Red);
          writeln(f,'   NO ES UNA FECHA VÁLIDA ');
          textColor(White);
          TextBackground(black);
          writeln(' Formato: [dia], [dia-mes],  [dia-mes-año] (dia de 1 a 31)  (mes de 1 a 12) ');
          writeln;
      end;
end;

procedure cargaRango(fi: String; ff: String);
var efi:TEsFecha;
   eff:TEsFecha;
   parametro2 : String;
begin
  efi:= esFecha(fi);
   if efi.esFecha then
      begin
        textColor(White);
        writeln(' FECHA INICIAL ',DatetoStr(efi.fecha));
      end else
      begin
          TextBackground(white);
          textColor(Red);
          writeln(fi,'   NO ES UNA FECHA VÁLIDA ');
          textColor(White);
          TextBackground(black);
          writeln(' Formato: [dia], [dia-mes],  [dia-mes-año] (dia de 1 a 31)  (mes de 1 a 12) ');
          writeln;
          Exit;
      end;
      eff:= esFecha(ff);
      if eff.esFecha  then
      begin
        textColor(White);
        writeln(' FECHA FINAL ',DatetoStr(eff.fecha));
      end else
      begin
          TextBackground(white);
           textColor(Red);
           writeln(ff,'   NO ES UNA FECHA VÁLIDA ');
             textColor(White);
             TextBackground(black);
           writeln(' Formato: [dia], [dia-mes],  [dia-mes-año] (dia de 1 a 31)  (mes de 1 a 12) ');
           writeln;
            Exit;
      end;
          parametro  := FormatDateTime('yyyy-MM-dd', efi.fecha);
          parametro2 := FormatDateTime('yyyy-MM-dd', eff.fecha);


      dibujaRango(parametro,parametro2, 'De '+FormatDateTime('dd-MM-yyyy', efi.fecha)+' a '+FormatDateTime('dd-MM-yyyy', eff.fecha));
end;

procedure dibujaLikes(titulo: string; para: string);
begin
     ClrScr;
  writeln();
  TextColor(Yellow);
  pintaCuadroDoble(titulo);
  TextColor(White);
  writeln();
  sql := 'select * from apuntes WHERE texto LIKE "%'+para+'%"  ';
  dbQuery.sql.Clear;
  dbQuery.sql.add(sql);
  dbQuery.Open;
  if dbQuery.RecordCount>0 then
  begin
  hayApuntes:=true;
  while not dbQuery.EOF do
  begin
    Writeln(' ', format('%5d', [dbQuery.FieldByName('ID').AsInteger])
      , ' ┤ ', FormatDateTime('hh:nn', dbQuery.FieldByName('fecha').AsDateTime), ' ├ ', dbQuery.FieldByName('texto').AsString);
    dbQuery.Next;
  end;
  writeln;
  end else
  begin
    TextColor(red);
    TextBackground(white);
    writeln('No hay apuntes con esa fecha');
    TextBackground(black);
    textcolor (white);
    hayApuntes:=false;
    writeln;
    exit;
  end;
  cierraDb;
  writeln;
end;


procedure dibujaTabla(titulo: string; para: string);
begin
   ClrScr;
  writeln();
  TextColor(Yellow);
  pintaCuadroDoble(titulo);
  TextColor(White);
  writeln();
  sql := 'select * from apuntes where substr(fecha, 1, 10) = "' + para + '";';
  dbQuery.sql.Clear;
  dbQuery.sql.add(sql);
  dbQuery.Open;
  if dbQuery.RecordCount>0 then
  begin
  hayApuntes:=true;
  while not dbQuery.EOF do
  begin
    Writeln(' ', format('%5d', [dbQuery.FieldByName('ID').AsInteger])
      , ' ┤ ', FormatDateTime('hh:nn', dbQuery.FieldByName('fecha').AsDateTime), ' ├ ', dbQuery.FieldByName('texto').AsString);
    dbQuery.Next;
  end;
  end else
  begin
    TextColor(red);
    TextBackground(white);
    writeln('No hay apuntes con esa fecha');
    TextBackground(black);
    textcolor (white);
    hayApuntes:=false;
    writeln;
    exit;
  end;
  cierraDb;
  writeln;
end;

procedure dibujaRango(fi: string; ff: string; tit: String);
begin
   ClrScr;
  writeln();
  TextColor(Yellow);
  pintaCuadroDoble(tit);
  TextColor(White);
  writeln();
  sql := 'select * from apuntes where substr(fecha, 1, 10) BETWEEN "'+fi+'" and "'+ff+'" ;';
  dbQuery.sql.Clear;
  dbQuery.sql.add(sql);
  dbQuery.Open;
    if dbQuery.RecordCount>0 then
    begin
     hayApuntes:=true;
  while not dbQuery.EOF do
  begin
    Writeln(' ', format('%5d', [dbQuery.FieldByName('ID').AsInteger])
      , ' ┤ ', FormatDateTime('dd-MM-yyyy hh:nn', dbQuery.FieldByName('fecha').AsDateTime), ' ├ ', dbQuery.FieldByName('texto').AsString);
    dbQuery.Next;
  end;
  end else
  begin
       TextColor(red);
       TextBackground(white);
    writeln('No hay apuntes con esa fecha');
     TextBackground(black);
    textcolor (white);
    hayApuntes:=false;
    writeln;
    exit;
  end;
 cierraDb;
  writeln;
end;

procedure grabaApunte(texto:String);
begin
   dbQuery.sql.Clear;
          dbQuery.sql.add('INSERT INTO apuntes (fecha,texto) values( datetime("now","localtime") ,"' + texto + '");');
          dbQuery.ExecSQL;
          dbTrans.Commit;
          textColor(Yellow);
          Write('Añadido: ');
          TextColor(White);
          writeln(texto);
end;
    procedure pideFechaYGraba;
  var
    f, h, texto, fc: string;
    fech,fecTemp: TDateTime;

  begin
    fecTemp:=now;
    textColor(White);
    Write('Fecha? d-m-a [Intro para hoy]: ');
    readln(f);
    if f='' then f:= FormatDateTime('dd-MM-yyyy', fecTemp) ;
    Write('Hora? h:m [Intro para esta hora]: ');
    readln(h);
     if h='' then h:= FormatDateTime('hh:nn', fecTemp) ;
    fs.TimeSeparator := ':';

    if TryStrToDateTime(f + ' ' + h, fech) then
    begin
      fc := (FormatDateTime('yyyy-MM-dd hh:nn', fech));
      writeln(FormatDateTime('dd-MM-yyyy hh:nn', fech));
    end
    else
    begin
      writeln('Fecha / Hora erróneas');

      Exit;
    end;

    writeln('apunte?');
    readln(texto);
    if Length(texto) > 2 then
    begin
      if (estado = True) then
      begin
        dbQuery.sql.Clear;
        dbQuery.sql.add('INSERT INTO apuntes (fecha,texto) values( "' + fc + '" ,"' + texto + '");');
        dbQuery.ExecSQL;
        dbTrans.Commit;
        textColor(Yellow);
        Write('Añadido: ');
        TextColor(White);
        writeln(texto);
      end;
    end
    else
    begin
      TextBackground(white);
      textColor(Red);
      writeln('ERROR: El apunte debe tener más de 2 caracteres ');
      TextColor(White);
      TextBackground(black);
      writeln;
    end;

    Exit;
  end;



  procedure borraId(id: integer);
  var
    ap: TRApunte;
    resp: string;
  begin
    ap := buscaApuntePorId(id);
    if ap.id > 0 then
    begin
      writeln('');
      textColor(Yellow);
      Write('  ¿Borrar apunte con el ID ' + IntToStr(id) + '? [S/N] ');
      TextColor(White);
      readln(resp);
      textColor(Yellow);
      if ((resp = 'S') or (resp = 's')) then
      begin
        if (estado = True) then
        begin
          dbQuery.sql.Clear;
          dbQuery.sql.add('DELETE FROM apuntes WHERE id=' + IntToStr(id) + ';');
          dbQuery.ExecSQL;
          dbTrans.Commit;
          textColor(Yellow);
          Writeln('  Borrado apunte ' + IntToStr(id));
          TextColor(White);
          WriteLn();

        end;
      end;
    end
    else
    begin

    end;
    TextColor(White);
  end;

  function buscaApuntePorId(id: integer): TRApunte;
  var
    datos: TRApunte;
  begin
    datos.id := -1;
    datos.texto := '';
    TextColor(white);
    WriteLn();
    sql := 'select * from apuntes where id=' + IntToStr(id) + ';';
    dbQuery.sql.Clear;
    dbQuery.sql.add(sql);
    dbQuery.Open;
    if dbQuery.RecordCount>0 then begin
    while not dbQuery.EOF do
    begin
      Writeln(' ', format('%5d', [dbQuery.FieldByName('ID').AsInteger])
        , ' ┤ ', FormatDateTime('dd-MM-yyyy  hh:nn', dbQuery.FieldByName('fecha').AsDateTime), ' ├ ', dbQuery.FieldByName('texto').AsString);

      datos.id := dbQuery.FieldByName('ID').AsInteger;
      datos.fecha := dbQuery.FieldByName('fecha').AsDateTime;
      datos.texto := dbQuery.FieldByName('texto').AsString;
      dbQuery.Next;

    end;
    writeln;
    end else
    begin
        TextColor(red);
        TextBackground(white);
    WriteLn('No encuentro ningún apunte con la ID: ', id);
     TextBackground(black);
    TextColor(white);
         writeln;
       exit;
    end;

    dbQuery.Close;
    Result := datos;
  end;

  procedure buscaId;
  begin

  end;

  procedure actualizaId(id: integer);
  var
    ap: TRApunte;
   fc,f,h,texto, resp: string;
    fech:TdateTime;
  begin
        ap := buscaApuntePorId(id);
    if ap.id > 0 then
    begin
      writeln('');
      textColor(Yellow);
      Write('  ¿Modificar apunte con ID ' + IntToStr(id) + '? S/N ');
      TextColor(White);
      readln(resp);
      textColor(Yellow);
      if ((resp = 'S') or (resp = 's')) then
      begin
        if (estado = True) then
        begin
           textColor(White);
           Write('Fecha? d-m-a [Intro para la misma]: ');
           readln(f);
           if f='' then f:= FormatDateTime('dd-MM-yyyy', ap.fecha) ;
           Write('Hora? h:m [Intro para la misma]: ');
           readln(h);
           if h='' then h:= FormatDateTime('hh:nn', ap.fecha) ;
           fs.TimeSeparator := ':';

    if TryStrToDateTime(f + ' ' + h, fech) then
    begin
      fc := (FormatDateTime('yyyy-MM-dd hh:nn', fech));
      writeln(FormatDateTime('dd-MM-yyyy hh:nn', fech));
    end
    else
    begin
      writeln('Fecha / Hora erróneas');

      Exit;
    end;

    writeln('¿apunte? [INTRO para el mismo]');
    readln(texto);
    if texto = '' then texto := ap.texto;
    if Length(texto) > 2 then
    begin
      if (estado = True) then
      begin
        dbQuery.sql.Clear;
        dbQuery.sql.add('UPDATE apuntes SET fecha= "'+ fc + '"  , texto= "' + texto + '" WHERE id= '+intTostr(id)+';');
        dbQuery.ExecSQL;
        dbTrans.Commit;
        textColor(Yellow);
        Write('Modificado: ');
        TextColor(White);
       Writeln(' ', format('%5d', [ap.id])
        , ' ┤ ', FormatDateTime('dd-MM-yyyy  hh:nn', fech), ' ├ ', texto);

      end;
    end
    else
    begin
      TextBackground(white);
      textColor(Red);
      writeln('ERROR: El apunte debe tener más de 2 caracteres ');
      TextColor(White);
      TextBackground(black);
      writeln;
    end;

    Exit;

        end;
      end;
    end
    else
    begin

    end;
    TextColor(White);

  end;




procedure cierraDb;
begin
  dbQuery.Close;
   sqlite3.Close;

end;

end.
