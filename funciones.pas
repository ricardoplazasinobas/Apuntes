unit funciones;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

     type
       TEsFecha = record
         esFecha : Boolean;
         fecha   : Tdate  ;
       end;
         function esFecha(f:String):TEsFecha;
         procedure pintaCuadroDoble(titulo: String);


implementation

function esFecha(f: String): TEsFecha;
var
  t:TDateTime;
  res: Boolean;
begin
 res := TryStrToDateTime(f,t);
 result.esFecha:=res;
 result.fecha:=t;
end;

procedure pintaCuadroDoble(titulo: String);
var x,l: integer;
begin
 l:= Length(titulo);
  write ('╔');
  for x:= 1 to l+2 do
  begin
     write ('═');
  end;
   writeln ('╗');
   writeln('║ ',titulo,' ║');
    write ('╚');
  for x:= 1 to l+2 do
  begin
     write ('═');
  end;
   writeln ('╝');


end;

end.

