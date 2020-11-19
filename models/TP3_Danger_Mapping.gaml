/***
* Name: TP3DangerMapping
* Author: franel
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model TP3DangerMapping

/* Insert your model definition here */

global {
	/** Insert the global definitions, variables and actions here */
	
	int nb_point_dangereux <- 10 parameter:'Nombre de points dangereux' category: 'Zone' min:1 max:20;
	int nbre_robot <- 5 parameter:'Nombre de Robots' category: 'Robot' min:2 max:10;
	
	//geometry shape <- rectangle(10#m,20#m);
	geometry background <- rectangle(20, 20);
	
	init{
		create Centre number: 1{
		}
		
		create Point_Dangereux number: nb_point_dangereux{
		}
		
		create Robot number: nbre_robot{
		}
	}
	
}

species name: Centre {
	rgb color init:rgb('gray');
	float size init: 6.0;
	list<Point_Dangereux> points_dangereux init: nil;
	point location -> {0.5, 0.5};
	
	aspect basic {
		draw circle(size) color:color;
	}
}

species name: Point_Dangereux {
	rgb color init:rgb('red');
	float size init: 1.5;
	float level init: rnd(10.0);
	point location <- any_location_in (background);
	
	aspect basic {
		draw circle(size) color:color;
	}
}

species name: Panneau {
	rgb color init:rgb('green');
	float size init: 0.9;
	float level;
	
	aspect basic {
		draw circle(size) color:color;
	}
}


species name: Robot skills:[moving]{
	rgb color init:rgb('blue');
	float size init: 1.0;
	float speed <- rnd(2.0) + 1.0;
	int rayon_communication init: 20;
	int rayon_observation init: 10;
	list<Point_Dangereux> point_dangeruex init: nil;
	Centre centre <- one_of(Centre);
	point location init: any_location_in (centre);
	
	geometry zone_visite;
	geometry zone_non_visite <- background;
	
	aspect basic {
		draw square(size) color:color;
	}
	
	reflex decouvrir when: zone_non_visite != nil {
		// On choisi un point dans la zone non visité
		
		//list<point> liste_points <- closest_points_with(location, zone_non_visite);
		//point x <- liste_points at 1;
		
		point x <- any_location_in (circle(rayon_observation));
		do goto target: x speed: speed;
		
		// On met à jour les zones visité
		zone_visite <- zone_visite + circle(rayon_observation);
		
		// On met à jour les zones non visité
		zone_non_visite <- background - zone_visite;
		
		// Si on rencontre un point dangerureux
		list<Point_Dangereux> liste <- (agents of_generic_species Point_Dangereux) at_distance rayon_observation;
		
		loop n over: liste {
			if point_dangeruex index_of n = -1 {
				add item: n to: point_dangeruex;
				// On crée un panneau si le panneau n'existe pas
				if length((agents of_generic_species Panneau) at_distance(0)) = 0 {
					create Panneau number: 1{
						location <- n.location;
						level <- n.level;
					}
				}
				
			}
		}
		
		// Si on rencontre un autre robot
		ask (agents of_generic_species Robot) at_distance rayon_observation {
			// On partage les zones visités
			myself.zone_non_visite <- myself.zone_non_visite + self.zone_non_visite;
			myself.zone_visite <- myself.zone_visite + self.zone_visite;
			self.zone_non_visite <- myself.zone_non_visite;
			self.zone_visite <- myself.zone_visite;
			
			// On partage la liste des points dangeureux
			loop n over: myself.point_dangeruex {
				if self.point_dangeruex index_of n = -1 {
					add item: n to: self.point_dangeruex;
				}
			}
		}
		
		// Si on est dans le rayon de communication avec le centre de control, on envois les informations
		ask (agents of_generic_species Centre) at_distance rayon_communication {
			// On partage la liste des points dangeureux
			loop n over: myself.point_dangeruex {
				if self.points_dangereux index_of n = -1 {
					add item: n to: self.points_dangereux;
				}
			}
		}
	}
	
	reflex retourner when: zone_non_visite = nil {
		do goto target: centre speed: speed;
	}
}

experiment NewModel type: gui {
	/** Insert here the definition of the input and output of the model */
	output {
		display Tutoriel2{
			species Centre aspect:basic;
			species Point_Dangereux aspect:basic;
			species Panneau aspect:basic;
			species Robot aspect:basic;
		}
	}
}
