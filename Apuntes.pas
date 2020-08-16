program MisApuntes;

{$mode objfpc}{$H+}

uses {$IFDEF UNIX}
  cthreads, {$ENDIF}
  Classes,
  SysUtils,
  CustApp,
  DateUtils,
  crt,
  Character,
  ulistados,
  funciones;
  type
  ap = class(TCustomApplication)
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure ponAyuda;

  end;




procedure ap.ponAyuda;
  begin
    Clrscr;
    GotoXY(15,3);
    Write('Fecha: ', dateTimeToStr(now));
    writeln;
    writeln('┌───────────────────────────────────────────────────────┐');
    writeln('│ GESTIÓN DE APUNTES EN TERMINAL POR RICARDO PLAZA  (c) │');
    writeln('└───────────────────────────────────────────────────────┘');
    writeln();
    writeln(' Uso: ', ' -h para ver esta ayuda');
    writeln();
    writeln(' AÑADIR');
    writeln(' Sin argumentos pide el apunte y espera respuesta. Lo añade con fecha de hoy. Apunte vacío sale del programa.');
    writeln(' [apunte] Sin argumentos añade el [apunte] indicado con la fecha de hoy');
    writeln(' -a  pide la fecha y el apunte y espera respuesta.');
    writeln();
    writeln(' ACTUALIZAR');
    writeln(' -u ' + 'Sin argumentos pide el apunte y espera respuesta. ');
    writeln(' -u ' + '[id] actualiza el apunte nº [id]');
    writeln();
    writeln(' LISTAR');
    writeln(' -v ' + '[id] para ver el apunte nº [id]');
    writeln(' -l ' + 'para listar todos apuntes');
    writeln(' -l ', '[dd-mm-aaaa]' + ' para listar apuntes de la fecha indicada');
    writeln(' -l ', '[dd-mm-aaaa] [dd-mm-aaaa]' + ' para listar apuntes de el periodo indicado');
    writeln(' -t ' + 'para listar apuntes de hoy');
    writeln(' -y ' + 'para listar apuntes de ayer');
    writeln();
    writeln(' BORRAR');
    writeln(' -b ' + '[id] para borrar el apunte nº [id]');
    writeln(' -d ' + '[dd-mm-aaaa] para borrar los apuntes de la fecha indicada');
    writeln(' -d ', '[dd-mm-aaaa] [dd-mm-aaaa]' + ' para borrar los apuntes de el periodo indicado');
    writeln();
    writeln(' BUSCAR');
    writeln(' -s ', '[texto]' + ' para buscar apunte con el texto indicado');

  end;

  procedure ap.DoRun;
  var
    texto, ii: string;
    x, i: integer;
  begin
    fs.ShortDateFormat := 'dd-MM-yyyy';
    fs.ShortTimeFormat := 'hh:nn';
    estado := False;
    compruebaCarpeta;

    if HasOption('h', 'help') then
    begin
      ponAyuda;
      Terminate;
      Exit;
    end;

    if estado = True then
    begin

      if HasOption('t') then
      begin
        cargaHoy;
        Terminate;
        Exit;
      end;

      if HasOption('y') then
      begin
        cargaAyer;
        Terminate;
        Exit;
      end;

      if HasOption('l') then
      begin
        if ParamCount = 2 then
        begin
          cargaFecha(paramstr(2));
          Terminate;
          Exit;
        end;
        if ParamCount = 3 then
        begin
         cargaRango(paramstr(2),paramstr(3));
          Terminate;
          Exit;
        end;
        cargaTodos;
        Terminate;
        Exit;
      end;

      if HasOption('a', 'add') then
      begin
        pideFechaYGraba;
        Terminate;
        Exit;
      end;

      if HasOption('s', 'search') then
      begin
         if ParamCount = 2 then
        begin
         buscaTexto(paramstr(2));
          Terminate;
          Exit;
        end;
        if ParamCount = 1 then
        begin
            buscaTexto('');
          Terminate;
          Exit;
        end;

      end;



      if HasOption('v') then
      begin
       if ((ParamCount = 2) and (TryStrToInt(Params[2], i))) then
        begin
          buscaApuntePorId(i);
        end
        else
        begin
          TextColor(yellow);
          repeat
            Write('  [INTRO] para salir ID?  -> ');
            readln(ii);

          until ((TryStrToInt(ii, i)) or (ii = ''));
          if ii = '' then
          begin
            TextBackground(white);
            textColor(Red);
            writeln('  Saliendo...');
            TextColor(White);
             TextBackground(black);
             writeln;
            Terminate;
            Exit;
          end;
            buscaApuntePorId(i);
        end;
        Terminate;
        Exit;
      end;

        if HasOption('u') then
        begin
          if ((ParamCount = 2) and (TryStrToInt(Params[2], i))) then
        begin
          actualizaId(i);
        end
        else
        begin
          TextColor(yellow);
          repeat
            Write('  [INTRO] para salir ID?  -> ');
            readln(ii);

          until ((TryStrToInt(ii, i)) or (ii = ''));
          if ii = '' then
          begin
            TextBackground(white);
            textColor(Red);
            writeln('  Saliendo...');
            TextColor(White);
            TextBackground(black);
            writeln;
            Terminate;
            Exit;
          end;

          actualizaId(i);
        end;
        Terminate;
        Exit;
      end;


      if HasOption('b', 'del') then
      begin

        if ((ParamCount = 2) and (TryStrToInt(Params[2], i))) then
        begin
          borraId(i);
        end
        else
        begin
          TextColor(yellow);
          repeat
            Write('  [INTRO] para salir ID?  -> ');
            readln(ii);

          until ((TryStrToInt(ii, i)) or (ii = ''));
          if ii = '' then
          begin
            TextBackground(white);
            textColor(Red);
            writeln('  Saliendo...');
            TextColor(White);
            TextBackground(black);
            writeln;
            Terminate;
            Exit;
          end;

          borraId(i);
        end;
        Terminate;
        Exit;
      end;

           if HasOption('d') then
      begin
        if ParamCount = 2 then
        begin
          borraFecha(paramstr(2));
          Terminate;
          Exit;
        end;
        if ParamCount = 3 then
        begin
         borraRango(paramstr(2),paramstr(3));
          Terminate;
          Exit;
        end;
        cargaTodos;
        Terminate;
        Exit;
      end;


      if ParamCount = 0 then
      begin

        writeln('apunte?');
        readln(texto);
      end
      else
      begin
        for x := 1 to paramCount do
        begin
          texto := texto + ParamStr(x) + ' ';
        end;
      end;
      if Length(texto) = 0 then
      begin
        Terminate;
        Exit;
      end;

      if Length(texto) > 2 then
      begin
        if (estado = True) then
        begin

          grabaApunte(texto);
          terminate;
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
      Terminate;
      Exit;

    end;
  end;


  constructor ap.Create(TheOwner: TComponent);
  begin
    inherited Create(TheOwner);
    StopOnException := True;
    fsInverso.ShortDateFormat := 'yyyy-MM-dd';
    fsInverso.ShortTimeFormat := 'hh:nn';
  end;

  destructor ap.Destroy;
  begin
    dbQuery.Close;
   sqlite3.Close;
   FreeAndNil(sqlite3);
    TextColor(white);
     TextBackground(black);
    inherited Destroy;
  end;

var
  Application: ap;
begin
  Application := ap.Create(nil);
  Application.Title:='Apuntes';
  Application.Run;
  Application.Free;
end.
