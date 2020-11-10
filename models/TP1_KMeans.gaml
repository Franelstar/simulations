/***
* Name: TP1KMeans
* Author: franel
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model TP1KMeans

/* Insert your model definition here */

global {
	int nb_point <- 100 parameter:'nbre Point' category: 'Points' min:100 max:500;
	int k <- 3 parameter:'Nombre de centre' category: 'Centre' min:2 max:10;
	
	rgb color_init <- rgb(150, 150, 150);
	int nbre_changement <- 1;
	
	init{
		create Point number: nb_point{
		}
		
		create Centre number: k{
		}
	}
	
	reflex fin {
		if nbre_changement = 0 {
			do halt;
		} else {
			nbre_changement <- 0;
		}
	}
}

species name:BasicAgent{
	point location;
	rgb color init:color_init;
	float size init: 1.0;
	
	aspect basic {
		draw circle(size) color:color;
	}
	
}

species name:Point parent: BasicAgent{
	float speed;
	
	// Mise à jour de la couleur
	reflex calculer {
		float x_caree <- 0.0;
		float y_caree <- 0.0;
		float distance_old <- -1.0;
		Centre new_centre <- nil;
        
        // Calcul de la distance avec le centre actuel
        if color != color_init {
        	Centre centre_old <- one_of(Centre where (each.color = color));
	        x_caree <- (centre_old.location.x - location.x) * (centre_old.location.x - location.x);
	        y_caree <- (centre_old.location.y - location.y) * (centre_old.location.y - location.y);
	        distance_old <- abs(sqrt(x_caree + y_caree));
        
        
	        // Parcour des autres centres pour mise à jour si nécessaire
	        loop agt over: (agents of_generic_species Centre where (each.color != color)) {
				x_caree <- (agt.location.x - location.x) * (agt.location.x - location.x);
		        y_caree <- (agt.location.y - location.y) * (agt.location.y - location.y);
		        float distance <- abs(sqrt(x_caree + y_caree));
		        
		        if distance < distance_old {
		        	new_centre <- agt;
		        	distance_old <- distance;
		        }
			}
		} else {
			// Parcour de tous les centres
	        loop agt over: (agents of_generic_species Centre) {
				x_caree <- (agt.location.x - location.x) * (agt.location.x - location.x);
		        y_caree <- (agt.location.y - location.y) * (agt.location.y - location.y);
		        float distance <- abs(sqrt(x_caree + y_caree));
		        
		        if distance_old = -1.0 {
		        	new_centre <- agt;
		        	distance_old <- distance;
		        }
		        
		        if distance < distance_old {
		        	new_centre <- agt;
		        	distance_old <- distance;
		        }
			}
		}
		
		if new_centre != nil {
			color <- new_centre.color;
			nbre_changement <- nbre_changement + 1;
		}
    }
}

species name:Centre parent: BasicAgent{
	float speed;
	float size init: 2.0;
	
	init {
		color <- rgb(rnd(255), rnd(255), rnd(255));
	}
	
	// Mise à jour du centre
	reflex mettre_a_jour {
		float x_total <- 0.0;
		float y_total <- 0.0;
		int total <- 0;
        ask (agents of_generic_species Point) where (each.color = color) {
        	total <- total + 1;
			x_total <- x_total + self.location.x;
			y_total <- y_total + self.location.y;
		}
		
		if total != 0 {
			location <- {x_total / total, y_total / total};
		}
    }
}

experiment NewModel type: gui {
	/** Insert here the definition of the input and output of the model */
	output {
		display KMEANS{
			species Point aspect:basic;
			species Centre aspect:basic;
		}
	}
}
	