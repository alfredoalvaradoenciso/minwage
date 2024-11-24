use "C:\Users\aalvarado\Downloads\peru_employment.dta", clear //ILOSTAT
destring time, gen(year)
keep obs_value year
tempfile l
save `l'

import excel "C:\Users\aalvarado\Downloads\ipc_nacional.xlsx", sheet("Base Dic.2021") cellrange(A4:F158) firstrow clear // INEI
replace Año=Año[_n-1] if Año[_n]==. 
replace Anual="" if Anual=="-"
destring Anual, replace
rename Año year
collapse (mean) ipc_nacional=Anual, by(year)
tempfile ipc_nacional
save `ipc_nacional'

import excel "C:\Users\aalvarado\Downloads\conference_board_tfp.xlsx", sheet("Annual") cellrange(BLW7:BLW82) firstrow clear // Conference Board
gen year=1949+_n
tempfile conference
save `conference'

use countrycode year ctfp cwtfp rtfpna rwtfpna if countrycode=="PER" using C:\Users\aalvarado\Downloads\pwt1001 , clear // PWT
tempfile pwt
save `pwt'

import delimited "https://estadisticas.bcrp.gob.pe/estadisticas/series/api/PN02124PM/txt/1991-1/2024-9", delimiters("\t") clear encoding(UTF-8)
replace mesaño=subinstr(mesaño,"Ene","Jan",.)
replace mesaño=subinstr(mesaño,"Abr","Apr",.)
replace mesaño=subinstr(mesaño,"Ago","Aug",.)
replace mesaño=subinstr(mesaño,"Dic","Dec",.)
gen date_monthly = monthly(mesaño, "MY")
format date_monthly %tm
rename remuneracionesremuneraciónmínima rmv
gen year = 1960 + floor(date_monthly / 12)
collapse (mean) rmv, by(year)
tempfile rmv
save `rmv'


import delimited https://estadisticas.bcrp.gob.pe/estadisticas/series/api/PM05000AA/txt/2001/2024, clear delimiters("\t") encoding(UTF-8)
rename (productobrutointernoporsectoresp año) (pbi year)
tempfile pbi
save `pbi'
import delimited https://estadisticas.bcrp.gob.pe/estadisticas/series/api/PM05217PA/txt/2001/2024, clear delimiters("\t") encoding(UTF-8)
rename (índicespromedioanualvariaciónpor año) (ipc_lima year)
tempfile a
save `a'
import delimited https://estadisticas.bcrp.gob.pe/estadisticas/series/api/PM05220PA/txt/2001/2024, clear delimiters("\t") encoding(UTF-8)
rename (índicespromedioanualvariaciónpor año) (ipc_lima_subyacente year)
merge 1:1 year  using  `a', nogen
merge 1:1 year  using  `pbi', nogen
merge 1:1 year  using  `pwt', nogen
merge 1:1 year  using  `conference', nogen
merge 1:1 year  using  `rmv', nogen
merge 1:1 year  using  `ipc_nacional', nogen
merge 1:1 year  using  `l', nogen



gen pl=pbi*1000/obs_value

tsset year
foreach v of varlist rtfpna rwtfpna pl {
gen `v'_pc=(`v'/L.`v'-1)*100
}

gen rmv_teo_pc=(ipc_nacional+TheConferenceBoard)
local initialyear=2013
gen rmv_teo=rmv*(1+0.15) if year==`initialyear'
replace rmv_teo=L.rmv_teo*(1+rmv_teo_pc/100) if year>=`initialyear'+1
tsline rmv rmv_teo if year>=`initialyear', legend(order(1 "RMV observada" 2 "RMV teorica")) name(a, replace) title("IPC Nacional, PTF") ytitle("S/") ttext(2024 )

gen rmv_teo_pc2=(ipc_lima_subyacente+TheConferenceBoard)
local initialyear=2008
gen rmv_teo2=rmv*(1+0.2) if year==`initialyear'
replace rmv_teo2=L.rmv_teo2*(1+rmv_teo_pc2/100) if year>=`initialyear'+1
tsline rmv rmv_teo2 if year>=`initialyear', legend(order(1 "RMV observada" 2 "RMV teorica")) name(b, replace) title("IPC subyacente Lima, PTF") ytitle("S/")

gen rmv_teo_pc3=(ipc_nacional+pl_pc)
local initialyear=2013
gen rmv_teo3=rmv*(1+0.15) if year==`initialyear'
replace rmv_teo3=L.rmv_teo3*(1+rmv_teo_pc3/100) if year>=`initialyear'+1
tsline rmv rmv_teo3 if year>=`initialyear', legend(order(1 "RMV observada" 2 "RMV teorica")) name(c, replace) title("IPC Nacional, PL") ytitle("S/")

gen rmv_teo_pc4=(ipc_lima_subyacente+pl_pc)
local initialyear=2008
gen rmv_teo4=rmv*(1+0.2) if year==`initialyear'
replace rmv_teo4=L.rmv_teo4*(1+rmv_teo_pc4/100) if year>=`initialyear'+1
tsline rmv rmv_teo4 if year>=`initialyear', legend(order(1 "RMV observada" 2 "RMV teorica")) name(d, replace) title("IPC subyacente Lima, PL") ytitle("S/")

grc1leg2 a b c d, leg(a) ycommon title(Salario Minimo observado vs teorico) note("Nota: RMV teorica = inflation (t-1)+ Δ productividad + labor supply elasticity de Reyna y Céspedes (2016).")

graph export C:\Users\aalvarado\Downloads\rmv_determination.png, replace
