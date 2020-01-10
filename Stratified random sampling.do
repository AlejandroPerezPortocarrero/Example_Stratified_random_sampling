
	clear all
	cls
	cd "D:\Alejandro\22_Oficios\Oficios enviados y por enviar\2019\12_Diciembre\Solicitud Planilla\SRI SIRIES SIAGIE"
	global bd "D:\Alejandro\22_Oficios\Oficios enviados y por enviar\2019\12_Diciembre\Solicitud Planilla"
	global bd2 "\\10.1.1.92\dipoda\1. Bases de datos\SIAGIE"
	
*|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||*
*| EGRESADOS y MATRICULADOS: SRI_SIRIES + SIAGIE 2014-2019
*|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||*	
	
	use dni bd using "$bd\egresadosuniv_sri_siries_2014-2019_unique.dta", clear
	append 	using "$bd\matriculadosuniv_sri_siries_2014-2019_unique.dta", keep(dni bd)
	duplicates drop dni, force
	
		* Muestra de control
		
		merge m:1 dni using "$bd2\siagie_2014-2019_5secu_aprobados.dta"	
		keep if _m==2 // Nos quedamos con los que no acceden a la universidad
		drop _m
		keep id_anio niv_mod cod_mod_school dni tipo_documento validado_reniec dsc_grado situacion_matricula sit_final_fase_regular sit_final_fase_recup dup  
		tostring cod_mod_school, replace
		
		merge m:1 cod_mod_school using "D:\Alejandro\1_Bases de datos\Censo Escolar\padron_2010-2018_short.dta" // Se completan datos del Censo Escolar para identificar las escuelas
		keep if _m==3 // Solo se mantienen a los no matcheados con SRI-SIRIES y que cuenten con información completa del Censo Escolar
		drop _m
		
		replace dni=subinstr(dni," ","",1)
		replace dni= upper(dni)
		replace dni= trim(dni)
		replace dni= itrim(dni)

		*drop if gestion=="2" // Se retiran a los colegios públicos de gestión privada al ser pocos
		drop if gestion==""
		drop anio
		drop dup
		
		* Stratified random sampling in Stata
		**************************************
		
		* Generando la muestra estratificada
		sort id_anio gestion dpto dni // Se identifica el estrato con el año de egreso del colegio (2014-2018), la gestión del mismo y el departamento en el que se encuentra
		by id_anio gestion dpto: count	// ``i''
		
		* Population in each strata (id1)
		preserve
		g id1=1
		collapse (count) id1, by(id_anio gestion dpto)
		tempfile input1
		save `input1', replace
		restore
		
		sort id_anio gestion dpto dni
		set seed 1003002849
		gen random = runiform()
		sort id_anio gestion dpto random
		by id_anio gestion dpto: keep if round(_n/_N,.01) <= .10 
		
		by id_anio gestion dpto: count	// ``j''	
	
		* Sample in each strata (id2)
		preserve
		g id2=1
		collapse (count) id2, by(id_anio gestion dpto)
		tempfile input2
		save `input2', replace
		restore	
		
		preserve
		u `input1', clear
		merge 1:1 id_anio gestion dpto using `input2'
		tempfile input3
		drop _m
		save `input3', replace		
		restore
		
		merge m:1 id_anio gestion dpto using `input3'
		drop _m
		
		* Compute the pweights
		g pw=id1/id2

		save auxi, replace
		
		*dta_equal . auxi // Comprobando la consistencia de la muestra		
				
		save "sample_nomatch_sri-siries.dta", replace


	