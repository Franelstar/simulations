/***
* Name: 14tutoriel5
* Author: franel
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model tutoriel5

/* Insert your model definition here */

global {
	file feu1 <- file("../includes/feu1.shp");
	file feu2 <- file("../includes/feu2.shp");
	file limiteF1 <- file("../includes/limitesF1.shp");
	file limiteF2 <- file("../includes/limitesF2.shp");
	file route <- file("../includes/route.shp");
	file bords <- file("../includes/bords.shp");
	file depart <- file("../includes/departd.shp");
	file arrivee <- file("../includes/arrivees.shp");
	
	geometry shape <- envelope(route);
	graph route_network;
	
	
	int nbre_transport <- 5 parameter:'Nombre de Transport' category: 'Transport' min:3 max:10;
		
	init{
		create Feu1 from: feu1;
		create Feu2 from: feu2;
		
		create L1 from: limiteF1;
		create L2 from: limiteF2;
		
		create Arrive from: arrivee;
		create Route from: route;
		route_network <- as_edge_graph(Route, 20);
		create Bords from: bords;
		create Depart from: depart;
		
		create moyenTransport number: nbre_transport{
			
		}
	}
}

species name:Feu1{
	int duration init: 600;
	rgb color init: rgb(255, 0, 0);
	int counter init: 0;
	
	aspect basic {
		draw shape color: color;
	}
	
	reflex fonction {
		counter <- counter + 1;
		
		if counter = duration {
			if color = rgb(255, 0, 0) {
				color <- rgb(0, 255, 0);
			} else {
				color <- rgb(255, 0, 0);
			}
			counter <- 0;
		}
	}
}

species name:Feu2{
	int duration init: 600;
	rgb color init: rgb(0, 255, 0);
	int counter init: 0;
	
	aspect basic {
		draw shape color: color;
	}
	
	reflex fonction {
		counter <- counter + 1;
		
		if counter = duration {
			if color = rgb(255, 0, 0) {
				color <- rgb(0, 255, 0);
			} else {
				color <- rgb(255, 0, 0);
			}
			counter <- 0;
		}
	}
}

species name:moyenTransport skills:[moving] {
	float speed <- rnd(20.0);
	rgb color init: rgb(150, 0, 150);
	float size init: 20.0;
	point target;
	Arrive a;
	
	aspect basic {
    	draw circle(size) color:color;
    }
    
    init {
    	Depart d <- one_of(Depart);
    	location <- d.location;
    	
    	Arrive not_destination <- Arrive closest_to(self);
    	ask Arrive where (each != not_destination) {
    		myself.a <- self;
    		myself.target <- self.location;
    	}
    }
    
    reflex deplacement {
    	// Observer les feux
    	if (length(L1 at_distance(5)) > 0 and (one_of(Feu1)).color = rgb(255, 0, 0)) or
    	 (length(L2 at_distance(5)) > 0 and (one_of(Feu2)).color = rgb(255, 0, 0)){
    		speed <- 0.0;
    	} else {
    		//Aller vers sa destination
    		speed <- rnd(20.0);
    		write(target);
    		do goto target: target on: route_network;
    	}
    }
    
    reflex mort {
    	if length([a] at_distance(10)) > 0 {
    		create moyenTransport number: 1{}
    		do die;
    	}
    }
}

species Route {
	aspect basic {
		draw line(shape.points, 2.0) color: #gray;
	}
}

species Bords {
	aspect basic {
		draw shape color: #black;
	}
}

species Depart {
	aspect basic {
		draw shape color: #blue;
	}
}

species Arrive {
	aspect basic {
		draw shape color: #red;
	}
}

species L1 {
	aspect basic {
		draw shape color: #yellow;
	}
}

species L2 {
	aspect basic {
		draw shape color: #yellow;
	}
}

experiment NewModel type: gui {
	/** Insert here the definition of the input and output of the model */
	output {
		display KMEANS{
			species Route aspect:basic;
			species Bords aspect:basic;
			species Depart aspect:basic;
			species Arrive aspect:basic;
			species Feu1 aspect:basic;
			species Feu2 aspect:basic;
			species L1 aspect:basic;
			species L2 aspect:basic;
			species moyenTransport aspect:basic;
		}
	}
}
	