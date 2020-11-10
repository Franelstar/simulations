/***
* Name: TP2fourmis
* Author: franel
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model TP2fourmis

/* Insert your model definition here */

global {
	/** Insert the global definitions, variables and actions here */
	
	int nbre_nid <- 1 parameter:'Nombre de nid' category: 'Nid' min:1 max:5;
	int nb_nouriture <- 3 parameter:'Nombre de nouriture' category: 'Nouriture' min:1 max:5;
	int nbre_fourmi <- 50 parameter:'Nombre de fourmi' category: 'Fourmi' min:10 max:100;
	
	init{
		create Nid number: nbre_nid{
		}
		
		create Nouriture number: nb_nouriture{
		}
		
		create Fourmi number: nbre_fourmi{
		}
	}
}

species name:Nid {
	rgb color init:rgb('gray');
	float size init: 5.0;
	
	aspect basic {
		draw circle(size) color:color;
	}
}

species name:Nouriture {
	rgb color init:rgb('green');
	int amount init: rnd(500);
	float size init: amount / 100;
	
	aspect basic {
		draw circle(size) color:color;
	}
	
	reflex mettre_a_jour_taille {
		size <- amount / 100;
		if amount <= 0 {
			do die;
		}
	}
}

species name:Marque {
	rgb color init:rgb("yellow");
	float size init: 0.3;
	int duration init: 10;
	Nouriture contenu;
	
	aspect basic {
		draw circle(size) color:color;
	}
	
	reflex deacrese {
		duration <- duration -1;
		if duration <= 0 {
			do die;
		}
	}
}

species name:Fourmi skills:[moving]{
	rgb color init:rgb('red');
	float size init: 1.0;
	float speed <- rnd(2.0) + 1.0;
	int amount init: 5;
	Nid nid <- one_of(Nid);
	list<Nouriture> food init: nil;
	float rayon_obseration <- 5.0;
	point location init: any_location_in (nid);
	bool transporte_nouriture init: false;
	
	aspect basic {
		draw square(size) color:color;
	}
	
	reflex chercher_nouriture when: length(food) = 0 {
		// Déplacement au hasard
		do action: wander speed: speed amplitude:180.0;
		
		// Chercher Nouriture dans le rayon d'observation
		list<Nouriture> nouritures <- Nouriture at_distance(rayon_obseration);
		loop n over: nouritures {
			if food index_of n = -1 {
				add item: n to: food;
			}
		}
		
		// Chercher les marques
		list<Marque> marques <- Marque at_distance(rayon_obseration);
		loop m over: marques {
			if food index_of m = -1 {
				add item: m.contenu to: food;
			}
		}
		
		// Chercher d'autres fourmis
		list<Fourmi> fourmis <- Fourmi at_distance(rayon_obseration);
		loop f over: fourmis {
			if f.food != nil {
				loop n over: f.food {
					if food index_of n = -1 {
						add item: n to: food;
					}
				}
			}
		}
		
		// On change d'état si la nouriture a été trouvée
		if length(food) > 0 {
			// Voir plus tard
		}
	}
	
	reflex aller_a_la_nouriture when: length(food) > 0 and !transporte_nouriture {
		// Aller à la nouriture
		do goto target: food at 0 speed: speed;
		
		// Si la nouriture est terminée
		 if dead((food at 0)) {
			//food <- nil;
			remove item: (food at 0) from: food;
		} else if  (food at 0) distance_to self < 1 { // Si on trouve la nouriture on la recupère
			(food at 0).amount <- (food at 0).amount - amount;
			transporte_nouriture <- true;
		}
	}
	
	reflex retour_au_nid when: transporte_nouriture {
		// Aller à la nouriture
		do goto target: nid speed: speed;
		
		// Laisser trace
		create Marque number: 1{
			location <- myself.location;
			contenu <- myself.food at 0;
		}
		
		// Si on arrive on nid, on dépose la nouriture
		if nid distance_to self < 1 {
			transporte_nouriture <- false;
		}
	}
}

experiment NewModel type: gui {
	/** Insert here the definition of the input and output of the model */
	output {
		display Tutoriel2{
			species Nid aspect:basic;
			species Nouriture aspect:basic;
			species Marque aspect:basic;
			species Fourmi aspect:basic;
		}
	}
}
