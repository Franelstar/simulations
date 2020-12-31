/***
* Name: 14tutoriel6
* Author: franel
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model tutoriel6

/* Insert your model definition here */

global {
	file objets_shp <- file("../includes/objets.shp");
	file panneau_shp <- file("../includes/panneau.shp");
	file salle_shp <- file("../includes/salle.shp");
	file sonneur_shp <- file("../includes/sonneur.shp");
	file sortie_shp <- file("../includes/sortie.shp");
	
	geometry shape <- envelope(salle_shp);
	
	int nbre_personne <- 20 parameter:'Nombre de Transport' category: 'Transport' min:10 max:100;
	
	bool alarme_declenche <- false;
	geometry zone_de_feu;
	geometry zone_des_objets <- envelope(objets_shp);
	
	int nbre_mort <- 0;
	int nbre_sortie <- 0;
		
	init{
		create Sortie from: sortie_shp;
		create Objet from: objets_shp;
		create Panneau from: panneau_shp;
		create Sonneur from: sonneur_shp;
		
		create Evacue number: nbre_personne{
			
		}
		
		create Feu_brule number: 1{
			
		}
	}
}

species name: Evacue skills:[moving] {
	rgb color init: rgb(0, 50, 255);
	int puissance <- 180;
	float speed <- 50.0;
	int rayon_observation <- 60;
	bool alerte <- false;
	point target;
	bool connaitre_sortie <- false;
	
	aspect basic {
		draw circle(40) color:color;
	}
	
	reflex deplacement {
		if target != nil {
			do goto target: target on: shape-zone_de_feu-zone_des_objets;
			
		} else if !alerte or (alerte and target = nil) {
			// do wander speed: speed bounds: shape-zone_de_feu-zone_des_objets;
			do wander speed: speed;
		}
		
		if alarme_declenche and !connaitre_sortie and target != nil  {
			target <- nil;
		}
	}
	
	// Meurt
	reflex meurt {
		if puissance <= 0 {
			nbre_mort <- nbre_mort + 1;
			do die;
		}
	}
	
	// Observer les autres, le feu et les panneaux de sortie
	reflex observer {
		// S'il ya alerte on se met en alerte
		if alarme_declenche {
			alerte <- alarme_declenche;
		}
		
		// Si il ya pas encore de feu, on observe les feux
		if !alerte {
			ask (agents of_generic_species Feu_brule) at_distance rayon_observation {
				myself.alerte <- true;
				// Si l'alarme n'a pas encore été déclenché
				if !alarme_declenche {
					myself.target <- (Sonneur closest_to (myself)).location;
				}
			}
		}
		
		// Si on est en alerte, on observe les autres et on les averti
		if alerte {
			ask (agents of_generic_species Evacue) at_distance rayon_observation {
				self.alerte <- myself.alerte;
				
				// Si on connait la sortie on les dit
				if connaitre_sortie {
					self.target <- myself.target;
				}
			}
		}
		
		// On observe les panneaux de sortie
		if alerte {
			ask (agents of_generic_species Panneau) at_distance rayon_observation {
				myself.target <- self.sortie.location;
				write("sortie");
				myself.connaitre_sortie <- true;
			}
		}
		
		// On observe les sorties
		if alerte {
			ask (agents of_generic_species Sortie) at_distance rayon_observation {
				myself.target <- self.location;
				myself.connaitre_sortie <- true;
			}
		}
	}
	
	// Si on est proche d'un sonneur et que on est en alerte et que la sonnerie n'est pas encore active
	reflex sonner when: alerte and !alarme_declenche {
		Sonneur sonneur <- Sonneur closest_to (self);
		if (sonneur distance_to(self)) = 0 {
			alarme_declenche <- true;
			write("Alerte déclenchée");
			target <- nil;
		}
	}
	
	// Si on est proche de la sortie et l'alarme est déclenché, on sort
	reflex sortie when: alerte{
		Sortie sortie_proche <- Sortie closest_to (self);
		if (sortie_proche distance_to(self)) = 0 {
			nbre_sortie <- nbre_sortie + 1;
			do die;
		}
	}
}

species name: Feu{
	int size <- 35;
}

species name: Feu_brule parent: Feu{
	rgb color <- rgb('red');
	int duree_vie <- 50 + rnd(30);
	int age <- 0;
	int rayon_affecte <- 30;
	
	init {
		zone_de_feu <- zone_de_feu + circle(size);
	}
	
	aspect basic {
		draw circle(size) color:color;
	}
	
	reflex propager when: flip(0.1){
		//On cherche les espaces vide autour
		list<point> liste;
		
		// On regarde à gauche
		float x_ <- location.x - 2 * size;
		list<agent> l1 <- (agents of_generic_species Feu) overlapping(circle(size, point(x_,location.y)));
		if length(l1) = 0 and x_ >= 0{
			add item: point(x_, location.y) to: liste;
		}
		
		// On regarde à droite
		x_ <- location.x + 2 * size;
		list<agent> l2 <- (agents of_generic_species Feu) overlapping(circle(size, point(x_,location.y)));
		if length(l2) = 0{
			add item: point(x_, location.y) to: liste;
		}
		
		// On regarde en haut
		float y_ <- location.y - 2 * size;
		list<agent> l3 <- (agents of_generic_species Feu) overlapping(circle(size, point(location.x,y_)));
		if length(l3) = 0 and x_ >= 0{
			add item: point(location.x, y_) to: liste;
		}
		
		// On regarde en bas
		y_ <- location.y + 2 * size;
		list<agent> l4 <- (agents of_generic_species Feu) overlapping(circle(size, point(location.x,y_)));
		if length(l4) = 0{
			add item: point(location.x, y_) to: liste;
		}
		
		if length(liste) > 0 and flip(0.8){
			liste <- shuffle (liste);
			point enfant <- liste at 0;
			create Feu_brule number: 1{
				self.location <- enfant;
			}
		}
	}
	
	// La vie du feu pour vérifier s'il doit nourir
	reflex vivre {
		if age >= duree_vie {
			create Feu_mort number: 1{
				location <- myself.location;
			}
			do die;
		}
		age <- age + 1;
	}
	
	// Affecte les personnes proches du feu
	reflex affecte {
		ask (agents of_generic_species Evacue) at_distance rayon_affecte {
			self.puissance <- self.puissance - 20;
			self.speed <- self.speed - self.puissance / 100;
		}
	}
}

species name: Feu_mort parent: Feu{
	rgb color <- rgb(60, 60, 60);
	
	aspect basic {
		draw circle(size) color:color;
	}
}

species Sonneur {
	
	aspect basic {
		draw shape color: #blue;
	}
}

species Panneau {
	Sortie sortie;
	
	init {
		sortie <- Sortie closest_to(self);
	}
	
	aspect basic {
		draw shape color: #green;
	}
}

species Objet {
	
	aspect basic {
		draw shape color: #gray;
	}
}

species Sortie {
	aspect basic {
		draw shape color: #green;
	}
}

experiment NewModel type: gui {
	/** Insert here the definition of the input and output of the model */
		
	output {
		monitor "Nombre de personne totale" value: nbre_personne;
		monitor "Nombre de personne morte" value: nbre_mort;
		monitor "Nombre de personne sortie" value: nbre_sortie;
		monitor "Nombre de personne encore dans la salle" value: nbre_personne - nbre_sortie - nbre_sortie;
		
		display KMEANS{
			species Evacue aspect:basic;
			species Sonneur aspect:basic;
			species Panneau aspect:basic;
			species Objet aspect:basic;
			species Sortie aspect:basic;
			species Feu_brule aspect:basic;
			species Feu_mort aspect:basic;
		}
	}
}
	