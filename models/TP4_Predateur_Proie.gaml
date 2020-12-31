/***
* Name: TP4PredateurProie
* Author: franel
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model TP4PredateurProie

/* Insert your model definition here */

global {
	/** Insert the global definitions, variables and actions here */
	
	int nbre_herbe <- 5 parameter:'Nombre Herbe' category: 'Herbe' min:1 max:10;
	int nbre_agneau <- 8 parameter:'Nombre Agneau' category: 'Annimal' min:5 max:20;
	int nbre_loup <- 2 parameter:'Nombre Loup' category: 'Animal' min:2 max:20;
	
	int s <- 50;
	geometry background <- rectangle(s, s);
	
	init{
		create Herbe number: nbre_herbe{
		}
		
		create Agneau number: nbre_agneau{
		}
		
		create Loup number: nbre_loup{
		}
	}
	
	// Condition d'arret
	reflex fin {
		if length((agents of_generic_species Herbe)) = 0 or length((agents of_generic_species Loup)) = 0 or length((agents of_generic_species Agneau)) = 0 {
			do halt;
		}
	}
}

species name:Creature {
	rgb color;
	float size;
	int mature;
	int taille;
	int creer_enfant;
	
	reflex grandir {
		
	}
}

species name:Herbe parent: Creature{
	int taille init: 50 max: 100;
	int taille_min <- 25;
	
	init {
		color <- rgb('green');
		size <- 1.0 ;
		creer_enfant <- 20;
	}
	
	aspect basic {
		draw circle(size) color:color;
	}

	reflex grandir {
		taille <- taille + 1;
		if taille > taille_min {
			creer_enfant <- creer_enfant -1;
		}
	}
	
	reflex nee when: creer_enfant <= 0{
		//On cherche les espaces vide autour
		list<point> liste;
		// On regarde à gauche
		float x_ <- location.x - 2 * size;
		list<agent> l1 <- (agents of_generic_species Herbe) overlapping(circle(size, point(x_,location.y)));
		if length(l1) = 0 and x_ >= 0{
			add item: point(x_, location.y) to: liste;
		}
		
		// On regarde à droite
		x_ <- location.x + 2 * size;
		list<agent> l2 <- (agents of_generic_species Herbe) overlapping(circle(size, point(x_,location.y)));
		if length(l2) = 0 and x_ <= s{
			add item: point(x_, location.y) to: liste;
		}
		
		// On regarde en haut
		float y_ <- location.y - 2 * size;
		list<agent> l3 <- (agents of_generic_species Herbe) overlapping(circle(size, point(location.x,y_)));
		if length(l3) = 0 and x_ >= 0{
			add item: point(location.x, y_) to: liste;
		}
		
		// On regarde en bas
		y_ <- location.y + 2 * size;
		list<agent> l4 <- (agents of_generic_species Herbe) overlapping(circle(size, point(location.x,y_)));
		if length(l4) = 0 and x_ >= s{
			add item: point(location.x, y_) to: liste;
		}
		
		if length(liste) > 0 and flip(0.8){
			liste <- shuffle (liste);
			point enfant <- liste at 0;
			write(enfant);
			create Herbe number: 1{
				self.location <- enfant;
			}
		}
		
		creer_enfant <- 20;
	}
	
	action etre_mange{
		//Réinitialiser la taille
		taille <- taille_min;
		
		//Réinitialiser le temps de creer enfant
		creer_enfant <- 20;
	}
}

species Animal parent: Creature skills:[moving] {
	int rayon_observation;
	int rayon_manger;
	point target;
	int montant_mange;
	int supporter_manger;
	int temps_creer_enfant;
	int vie;
	float speed;
}

species Agneau parent: Animal {
	reflex checher_herbe {
		if montant_mange < 200 {
			// Déplacement par hasard
			if target = nil{
				do wander;
			} else {
				do goto target:target;
			}
			
			//Observer les herbes
			list<Herbe> liste <- (agents of_generic_species Herbe) at_distance rayon_observation;
			if length(liste) > 0{
				target <- (liste at 0).location;
			}
			
			//S'il ya une herbe dans le rayon_manger
			ask (agents of_generic_species Herbe) at_distance rayon_manger {
				do etre_mange;
				myself.target <- nil;
				myself.montant_mange <- self.taille;
				myself.supporter_manger <- 50;
			}
		} else {
			do wander;
		}
	}
	
	reflex vivant {
		//Diminuer montatt mangé
		montant_mange <- montant_mange --1;
		
		// On augemnte le temps de creer enfant
		temps_creer_enfant <- temps_creer_enfant + 1;
		
		if montant_mange = 0 {
			supporter_manger <- supporter_manger - 1;
		}
		
		if supporter_manger = 0 {
			do die;
		}
	}
	
	reflex creer_enfant when: temps_creer_enfant >= vie {
		create Agneau number: 1{
		}
		
		temps_creer_enfant <- 0;
	}
	
	init {
		color <- rgb('blue');
		size <- 2.0;
		rayon_observation <- 10;
		rayon_manger <- 5;
		montant_mange <- 80;
		supporter_manger <- 20;
		temps_creer_enfant <- 0;
		vie <- rnd(50, 100);
		speed <- 3.0;
	}
	
	aspect basic {
		draw circle(size) color:color;
	}
}

species Loup parent: Animal {
	reflex checher_herbe {
		if montant_mange < 200 {
			// Déplacement par hasard
			if target = nil{
				do wander;
			} else {
				do goto target:target;
			}
			
			//Observer les agneaux
			list<Agneau> liste <- (agents of_generic_species Agneau) at_distance rayon_observation;
			if length(liste) > 0{
				target <- (liste at 0).location;
			}
			
			//S'il ya un agneau dans le rayon_manger
			ask (agents of_generic_species Agneau) at_distance rayon_manger {
					myself.target <- nil;
					myself.montant_mange <- self.montant_mange;
					myself.supporter_manger <- 80;
					do die;
			}
		} else {
			do wander;
		}
	}
	
	reflex vivant {
		//Diminuer montatt mangé
		montant_mange <- montant_mange - 1;
		
		// On augemnte le temps de creer enfant
		temps_creer_enfant <- temps_creer_enfant + 1;
		
		if montant_mange = 0 {
			supporter_manger <- supporter_manger - 1;
		}
		
		if supporter_manger = 0 {
			do die;
		}
	}
	
	reflex creer_enfant when: temps_creer_enfant >= vie {
		create Loup number: 1{
		}
		
		temps_creer_enfant <- 0;
	}
	
	init {
		color <- rgb('red');
		size <- 2.5;
		rayon_observation <- 15;
		rayon_manger <- 8;
		montant_mange <- 100;
		supporter_manger <- 30;
		temps_creer_enfant <- 0;
		vie <- rnd(100, 200);
		speed <- 4.0;
	}
	
	aspect basic {
		draw circle(size) color:color;
	}
}

experiment NewModel type: gui {
	/** Insert here the definition of the input and output of the model */
	output {
		display Forest{
			species Herbe aspect:basic;
			species Agneau aspect:basic;
			species Loup aspect:basic;
		}
	}
}
