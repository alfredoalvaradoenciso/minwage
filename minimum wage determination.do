gl root "https://github.com/alfredoalvaradoenciso/minwage/raw/refs/heads/main/"

clear

input year elasticity
2004	0.25
2005	0.27
2006	0.36
2007	0.22
2008	0.20
2009	0.18
2010	0.18
2011	0.19
2012	0.15
2013	0.15
2014	0.15
2015	0.15
2016	0.15
2017	0.15
2018	0.15
2019	0.15
2020	0.15
2021	0.15
2022	0.15
2023	0.15
2024	0.15
end
tempfile elasticity
save `elasticity'

use $root/peru_employment.dta, clear //ILOSTAT
destring time, gen(year)
keep obs_value year
tempfile l
save `l'

import excel $root/ipc_nacional.xlsx, sheet("Base Dic.2021") cellrange(A4:F158) firstrow clear // INEI
replace Año=Año[_n-1] if Año[_n]==. 
replace Anual="" if Anual=="-"
destring Anual, replace
rename Año year
collapse (mean) ipc_nacional=Anual, by(year)
tempfile ipc_nacional
save `ipc_nacional'

import excel $root/conference_board_tfp.xlsx, sheet("Annual") cellrange(BLW7:BLW82) firstrow clear // Conference Board
gen year=1949+_n
tempfile conference
save `conference'

use countrycode year ctfp cwtfp rtfpna rwtfpna if countrycode=="PER" using $root/pwt1001 , clear // PWT
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
merge 1:1 year  using  `elasticity', nogen


gen pl=pbi*1000/obs_value

tsset year
foreach v of varlist rtfpna rwtfpna pl {
gen `v'_pc=(`v'/L.`v'-1)*100
}

local rmv="rmv_teo"
gen `rmv'_pc=(ipc_nacional+TheConferenceBoard)
local initialyear=2013
gen `rmv'=rmv if year==`initialyear'
replace `rmv'=L.`rmv'*(1+`rmv'_pc/100) if year>=`initialyear'+1
replace `rmv'=`rmv'*(1+elasticity)
tsline rmv `rmv' if year>=`initialyear', legend(order(1 "RMV observada" 2 "RMV teorica")) name(a, replace) title("IPC Nacional, PTF") ytitle("S/") ttext(1148 2025  "1138" 1015 2025  "1025")

local rmv="rmv_teo2"	
gen `rmv'_pc=(ipc_lima_subyacente+TheConferenceBoard)
local initialyear=2008
gen `rmv'=rmv if year==`initialyear'
replace `rmv'=L.`rmv'*(1+`rmv'_pc/100) if year>=`initialyear'+1
replace `rmv'=`rmv'*(1+elasticity)
tsline rmv `rmv' if year>=`initialyear', legend(order(1 "RMV observada" 2 "RMV teorica")) name(b, replace) title("IPC subyacente Lima, PTF") ytitle("S/") ttext(835 2024  "835" 1025 2025  "1025")

local rmv="rmv_teo3"
gen `rmv'_pc=(ipc_nacional+pl_pc)
local initialyear=2013
gen `rmv'=rmv if year==`initialyear'
replace `rmv'=L.`rmv'*(1+`rmv'_pc/100) if year>=`initialyear'+1
replace `rmv'=`rmv'*(1+elasticity)
tsline rmv `rmv' if year>=`initialyear', legend(order(1 "RMV observada" 2 "RMV teorica")) name(c, replace) title("IPC Nacional, PL") ytitle("S/")  ttext(1471 2024  "1471" 1025 2025  "1025")

local rmv="rmv_teo4"
gen `rmv'_pc=(ipc_lima_subyacente+pl_pc)
local initialyear=2008
gen `rmv'=rmv if year==`initialyear'
replace `rmv'=L.`rmv'*(1+`rmv'_pc/100) if year>=`initialyear'+1
replace `rmv'=`rmv'*(1+elasticity)
tsline rmv `rmv' if year>=`initialyear', legend(order(1 "RMV observada" 2 "RMV teorica")) name(d, replace) title("IPC subyacente Lima, PL") ytitle("S/") ttext(1322 2024  "1322" 1025 2025  "1025")

*grc1leg2 a b c d, leg(a) ycommon title(Salario Minimo observado vs teorico) note("Nota: RMV teorica = inflation{sub:t-1}+ Δ{sub:t} productividad")
*graph export C:\Users\aalvarado\Downloads\rmv_determination_sine.png, replace

grc1leg2 a b c d, leg(a) ycommon title(Salario Minimo observado vs teorico) note("Nota: RMV teorica = inflation{sub:t-1}+ {&Delta}{sub:t} productividad + {&epsilon}{sub:t}, donde {&epsilon} = elasticidad de la oferta laboral de Reyna y Céspedes (2016).")
graph export C:\Users\aalvarado\Downloads\rmv_determination_cone.png, replace
