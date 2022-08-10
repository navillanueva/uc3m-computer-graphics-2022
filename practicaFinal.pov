#include "colors.inc"
#include "functions.inc"
#include "textures.inc"
#include "transforms.inc"
//---------------------------------------
// Switches (the value 0 turns a switch off)
//---------------------------------------
#declare RadOK=2; // 0 = no rad, 1 = test rad, 2 = final rad
#declare MediaOK=1; // media = 1 creates a subtle haze
#declare SaveRadOK=0; // save radiosity data for pass 1
#declare LoadRadOK=0; // load radiosity data for pass 2
#declare AreaOK=1; // subtle area light
#declare Ref=1; // intensity of reflections, use 0 to turn off it completely

#declare BuildingOK=1; // building
#declare SidewalkOK=1; // sidewalk and road
#declare MiniOK=1; // Mini Cooper car

//---------------------------------------
// Settings
//---------------------------------------
#default {finish {ambient 0}}
global_settings {
    max_trace_level 20
    //---------------------------------------
    // change gamma if necessary (scene too bright for instance)
    //---------------------------------------
    assumed_gamma 1
    //---------------------------------------
    noise_generator 2
    #if (RadOK>0)
        radiosity{
            #switch (RadOK)
                #case (1)
                    count 35 error_bound 1.8 
                #break
                #case (2)
                    count 300 error_bound 0.1 
                #break
            #end    
            nearest_count 2 
            recursion_limit 1  
            low_error_factor 1 
            gray_threshold 0 
            minimum_reuse 0.015 
            brightness 2 
            adc_bailout 0.01/2      
            normal on
            media off
            #if (SaveRadOK=1) // saves the radiosity values in the first pass
                save_file "mini.rad"
            #else
                #if (LoadRadOK=1) // loads the radiosity values in the second pass
                    pretrace_start 1
                    pretrace_end 1
                    load_file "mini.rad"
                    always_sample off
                #end
            #end
        }
    #end
}

//---------------------------------------
// Camera
//---------------------------------------
#declare car_location=<9.4,0.02,-3>;
#declare cam_location= <17, 1, -10>;
#declare cam_lookat= <7,2.8,0>;

camera {
    location  cam_location
    direction z*1.5
    right     x*image_width/image_height
    look_at   cam_lookat
} 





//---------------------------------------
// Night
//---------------------------------------  


#macro GammaColor(COLOR,G,L)
    rgb <pow(COLOR.red,G),pow(COLOR.green,G),pow(COLOR.blue,G)>*L
#end 
                        
#declare C_Moon  = GammaColor(<79, 105, 136>/255,0.4,1);
#declare xMoon=60;
#declare yMoon=79;
#declare posMoon=vaxis_rotate(vaxis_rotate(-z*10000,x,xMoon),y,yMoon);
 


    
fog {     
    fog_type 2
    distance 110
    color White  
    fog_offset 2 
    fog_alt    1  }
    //turbulence 0.5  }
    /*fog_type   2
     distance   80
     color      White
     fog_offset 10
     fog_alt    1.0
     turbulence 0.8
    }  */

    
    
//---------------------------------------
// Sky
//---------------------------------------
#declare C_Sky=rgb <87,114,165>/165;

box{-0.99,0.99
    texture{
        pigment{
            pigment_pattern{
                function {min(1,max(0,y))}
                poly_wave 0.6
                scale <1/3,1,1/3>
                turbulence 0.2
                lambda 2
            }
            pigment_map{ // creates some sort of skyline, mostly useless
                [0 Black]
                [0.15 average
                    pigment_map{
                        [1 cells scale <1/30,1/2,1/30>*2 color_map{[0.5 Black][0.5 C_Sky]}]
                        [1 cells scale <1/40,1/4,1/40>*2 color_map{[0.5 Black][0.5  C_Sky]}]
                    }
                ]
                [0.15 color C_Sky]
                [1 rgb 0.5*<88,120,157>/255]
            }
            
        }
        finish{ambient 2 diffuse 0}
    }
    hollow
    scale 1000
    rotate y*80
    no_shadow
}

//---------------------------------------
// Scattering media to create some haze effect
//---------------------------------------
#if (MediaOK)
    box{
        <-100,-1,-10>, <100,30,10>
        texture{pigment{Clear}finish{ambient 0 diffuse 0}}
        hollow
        interior{
            media{
                scattering{2,0.002 extinction 1}
            }
        }
    }
#end 


#declare T_Clear=texture{pigment{Clear} finish{ambient 0 diffuse 0}}

//---------------------------------------
// Buildings
//---------------------------------------
union{
    //---------------------------------------
    // Sidewalk and road
    //---------------------------------------
    #if (SidewalkOK=1)
        #debug "sidewalk\n"
        #declare P_Road=pigment{image_map{jpeg "bd_road2" interpolate 2} rotate z*90} 
        #declare F_Road=finish{ambient 0 diffuse 0.7 specular 0.1 roughness 0.02}// reflection{0,0.2*Ref}}

        #declare P_Concrete=pigment{image_map{jpeg "bd_concrete2" interpolate 2}} 
        #declare N_Concrete=normal{bump_map{jpeg "bd_concrete_bump" interpolate 2} bump_size 0.5}
        #declare F_Concrete=finish{ambient 0 diffuse 0.5 specular 0.3 roughness 0.15}
        //---------------------------------------
        // sidewalk
        //---------------------------------------
        #declare T_sidewalk_mat=texture{
            pigment{P_Concrete}
            normal{N_Concrete}
            finish{F_Concrete}
            scale <2453/1573,1,1>*2/3
        }
        #include "bd_sidewalk_o.inc"
        #declare Sidewalk=object{ P_Figure_1 }

        //---------------------------------------
        // cover
        //---------------------------------------
        #declare T_cover_mat=texture{
            pigment{image_map{jpeg "bd_cover" interpolate 2} rotate z*90}
            normal{bump_map{jpeg "bd_cover_bmp" interpolate 2} rotate z*90}
            finish{ambient 0 diffuse 0.4 specular 0.1 roughness 1/20}
        }
        #include "bd_cover_o.inc"
        #declare Cover=object{ P_Figure_1 }

        //---------------------------------------
        // border
        //---------------------------------------
        #declare C_Border=rgb <1,0.8,0.02>;
        #declare F_Border=finish{ambient 0 diffuse 0.5 specular 0.1 roughness 0.15}
        #declare P_Border=pigment{P_Concrete scale <2453/1573,1,1>*2 rotate x*45}
        #declare T_border_mat = texture{
            pigment_pattern{
                gradient x 
                scale 6 
                triangle_wave 
                color_map{[0.46 Black][0.5 White]}
                translate x*-0.31
            }
            texture_map{
                [0 pigment{P_Border}normal{granite 0.2 scale 1/3}finish{F_Border}]
                [1 pigment{
                        average
                        pigment_map{
                            [1 wrinkles turbulence 0.1 pigment_map{[0 color C_Border*1.3][0.45 color C_Border*0.5][0.68 color C_Border][0.69 P_Border]}]
                            [1 P_Border]
                        }
                    }
                    normal{granite 0.1 scale 1/3}
                    finish{F_Border}
                ]
            }
        }
        #include "bd_border_o.inc"
        #declare Border=object{ P_def_obj }
        
        //---------------------------------------
        // road
        //---------------------------------------
        // the road is made with a tileable height_field
        
        #declare RoadUnit=height_field{
            jpeg "bd_road_hf3"
            smooth
            texture{
                pigment{P_Road}
                finish{F_Road}
                rotate x*90
            }
        }
        
        #declare Road=union{
            object{RoadUnit}
            object{RoadUnit translate z}
            object{RoadUnit translate z*2}
            object{RoadUnit translate z*3}
            object{RoadUnit translate z*4}
            union{
                object{RoadUnit}
                object{RoadUnit translate z}
                object{RoadUnit translate z*2}
                object{RoadUnit translate z*3}
                object{RoadUnit translate z*4}
                translate x
            }
            union{
                object{RoadUnit}
                object{RoadUnit translate z}
                object{RoadUnit translate z*2}
                object{RoadUnit translate z*3}
                object{RoadUnit translate z*4}
                translate x*2
            }
            scale <174/237,0.025/3,1>*3
            rotate y*90
            translate <-15,0,6>
        }

        //---------------------------------------
        // Place the sidewalk and road
        //---------------------------------------
        #declare Ground=union{
            union{
                object{Cover}
                object{Sidewalk}
                object{Border}
                rotate x*-90
                scale 4/12.649749
                scale <-1,1,1>
                translate -z*3.01+y*0.14
            }
            object{Road}
        }
        object{Ground rotate y*180 translate -z*2}
    #end

    //---------------------------------------
    // Building
    //---------------------------------------

    #if (BuildingOK=1)
        #debug "building\n"
        #declare B=-1; // general bump value
        
        #declare T_Glass = texture{
            pigment{rgbf <0.98,0.95,0.9,0.9>}
            normal{bumps -0.005 scale 1} 
            finish{ambient 0 diffuse 0.45 specular 1 roughness 1/1000 conserve_energy reflection{0.3*Ref,0.9*Ref fresnel on}}
        }
        #declare C_Wall=rgb <115,110,94>/255;
        #declare C_Wall=GammaColor(C_Wall,2,1.5);
        #declare T_Wall0=texture{pigment{rgbt <C_Wall.red,C_Wall.green,C_Wall.blue,0.7>} finish{ambient 0 diffuse 1}}
        #declare T_Wall=texture{pigment{White*0.5+Yellow*0.5}}
        #declare T_Window=texture{
            pigment{image_map{jpeg "bd_window" interpolate 2}} 
            finish{ambient 0 specular 0.3 roughness 1/30 diffuse 0.7}
        }
        #declare T_DEFAULT = texture{T_Wall}
        
        
        #declare T_def_mat=texture{pigment{image_map{jpeg "bd_corner2" interpolate 2}} normal{bump_map{jpeg "bd_corner2_bump" interpolate 2} bump_size B} finish{ambient 0 diffuse 1}}texture{T_Wall0}
        #include "bd_corner2_o.inc"
        #declare P_corner2=object{ P_Figure_1 }
        
        // columns have to be reloaded to get different textures...
        #declare T_column2_mat=texture{pigment{image_map{jpeg "bd_column2" interpolate 2}} normal{bump_map{jpeg "bd_column2_bump" interpolate 2} bump_size B} finish{ambient 0 diffuse 1}}texture{T_Wall0}
        #include "bd_column2_o.inc"
        #declare P_column2=object{ P_Figure_1 }
        
        #declare T_column2_mat=texture{pigment{image_map{jpeg "bd_column2b" interpolate 2}} normal{bump_map{jpeg "bd_column2b_bump" interpolate 2} bump_size B} finish{ambient 0 diffuse 1}}texture{T_Wall0}
        #include "bd_column2_o.inc"
        #declare P_column2b=object{ P_Figure_1 }

        #declare T_column2_mat=texture{pigment{image_map{jpeg "bd_column2c" interpolate 2}} normal{bump_map{jpeg "bd_column2c_bump" interpolate 2} bump_size B} finish{ambient 0 diffuse 1}}texture{T_Wall0}
        #include "bd_column2_o.inc"
        #declare P_column2c=object{ P_Figure_1 }

        #declare T_ledge2w_mat=texture{pigment{image_map{jpeg "bd_ledge2w" interpolate 2}} normal{bump_map{jpeg "bd_ledge2w_bump" interpolate 2} bump_size B} finish{ambient 0 diffuse 1}}texture{T_Wall0}
        #include "bd_ledge2w_o.inc"
        #declare P_ledge2w=object{ P_Figure_1 }
        
        #declare T_ledge2_mat=texture{pigment{image_map{jpeg "bd_ledge2" interpolate 2} scale <1/6,1,1>*2} normal{bump_map{jpeg "bd_ledge2_bump" interpolate 2} bump_size B scale <1/6,1,1>*2} finish{ambient 0 diffuse 0.8}}texture{T_Wall0}
        #include "bd_ledge2_o.inc"
        #declare P_ledge2=object{ P_Figure_1 }
        
        #declare T_corner1b_mat=texture{pigment{image_map{jpeg "bd_corner1b" interpolate 2} scale <1,1,1>} normal{bump_map{jpeg "bd_corner1b_bump" interpolate 2} bump_size B} finish{ambient 0 diffuse 1}}texture{T_Wall0}
        #include "bd_corner1b_o.inc"
        #declare P_corner1b=object{ P_Figure_1 }
        
        #declare T_front1a_mat=texture{pigment{image_map{jpeg "bd_front1a" interpolate 2} scale <1,1,1>} normal{bump_map{jpeg "bd_front1a_bump" interpolate 2} bump_size B} finish{ambient 0 diffuse 1}}texture{T_Wall0}
        #include "bd_front1a_o.inc"
        #declare P_front1a=object{ P_Figure_1 }
        
        #declare T_corner1a_mat=texture{pigment{image_map{jpeg "bd_front1" interpolate 2} scale <1,0.5,1>} normal{bump_map{jpeg "bd_front1_bump" interpolate 2} bump_size B/2 scale <1,0.5,1>} finish{ambient 0 diffuse 1}}
        #include "bd_corner1a_o.inc"
        #declare P_corner1a=object{ P_Figure_1  }
        
        #declare T_corner1_mat=texture{pigment{image_map{jpeg "bd_corner1" interpolate 2} scale <1,1,1>} normal{bump_map{jpeg "bd_corner1_bump" interpolate 2} bump_size B} finish{ambient 0 diffuse 1}}texture{T_Wall0}
        #include "bd_corner1_o.inc"
        #declare P_corner1=object{ P_Figure_1  }
        
        #declare T_front1_mat=texture{pigment{image_map{jpeg "bd_front1" interpolate 2} scale <1,1,1>} normal{bump_map{jpeg "bd_front1_bump" interpolate 2} bump_size B/2} finish{ambient 0 diffuse 1}}
        #include "bd_front1_o.inc"
        #declare P_front1=object{ P_Figure_1 }
        
        // columns and bricks have to be reloaded to get different textures...
        #declare T_column1_mat=texture{pigment{image_map{jpeg "bd_column1" interpolate 2}} normal{bump_map{jpeg "bd_column1_bump" interpolate 2} bump_size B} finish{ambient 0 diffuse 1}}texture{T_Wall0}
        #include "bd_column1_o.inc"
        #declare P_column1=object{ P_Figure_1 }
        
        #declare T_column1_mat=texture{pigment{image_map{jpeg "bd_column1b" interpolate 2}} normal{bump_map{jpeg "bd_column1b_bump" interpolate 2} bump_size B} finish{ambient 0 diffuse 1}}texture{T_Wall0}
        #include "bd_column1_o.inc"
        #declare P_column1b=object{ P_Figure_1 }
        
        #declare T_column1_mat=texture{pigment{image_map{jpeg "bd_column1c" interpolate 2}} normal{bump_map{jpeg "bd_column1c_bump" interpolate 2} bump_size B} finish{ambient 0 diffuse 1}}texture{T_Wall0}
        #include "bd_column1_o.inc"
        #declare P_column1c=object{ P_Figure_1 }
        
        #declare T_column1_mat=texture{pigment{image_map{jpeg "bd_column1d" interpolate 2}} normal{bump_map{jpeg "bd_column1d_bump" interpolate 2} bump_size B} finish{ambient 0 diffuse 1}}texture{T_Wall0}
        #include "bd_column1_o.inc"
        #declare P_column1d=object{ P_Figure_1 }
        
        #declare T_bricks1_mat=texture{pigment{image_map{jpeg "bd_bricks1" interpolate 2}} normal{bump_map{jpeg "bd_bricks1_bump" interpolate 2} bump_size B} finish{ambient 0 diffuse 1}}texture{T_Wall0}
        #include "bd_bricks1_o.inc"
        #declare P_bricks1=object{ P_Figure_1 }
        
        #declare T_bricks1_mat=texture{pigment{image_map{jpeg "bd_bricks2" interpolate 2}} normal{bump_map{jpeg "bd_bricks2_bump" interpolate 2} bump_size B} finish{ambient 0 diffuse 1}}texture{T_Wall0}
        #include "bd_bricks1_o.inc"
        #declare P_bricks2=object{ P_Figure_1 }
        
        #declare T_dtop1a_mat = texture{pigment{image_map{jpeg "bd_doortop" interpolate 2}} normal{bump_map{jpeg "bd_doortop_bump" interpolate 2} bump_size B} finish{ambient 0 diffuse 1}}texture{T_Wall0}
        #declare T_dtop1b_mat = texture{T_dtop1a_mat}texture{T_Wall0}
        #declare T_dtop1c_mat = texture{T_dtop1a_mat}texture{T_Wall0}
        #declare T_dtop1d_mat = texture{T_dtop1a_mat}texture{T_Wall0}
        
        #include "bd_doortop_o.inc"
        
        #declare P_doortop=object{ P_Figure_1 }
        
        #declare T_dframe_mat = texture{T_front1_mat}
        
        #include "bd_dframe_o.inc"
        
        #declare T_glass1d_mat = texture{T_Glass} 
        #declare T_glass1_mat = texture{T_Glass}
        #declare T_glass2_mat = texture{T_Glass}
        #include "bd_glass_o.inc"

        // the window models have to be reloaded to get a different texture each time
        #declare T_window1_mat = texture{T_Window}
        #include "bd_window1_o.inc"
        #declare P_window1_left=object{P_def_obj}

        #declare T_window1_mat = texture{T_Window rotate z*90}
        #include "bd_window1_o.inc"
        #declare P_window1_right=object{P_def_obj}

        #declare T_window2_mat = texture{T_Window}
        #include "bd_window2_o.inc"
        #declare P_window2_1=object{P_def_obj}

        #declare T_window2_mat = texture{T_Window rotate z*90}
        #include "bd_window2_o.inc"
        #declare P_window2_2=object{P_def_obj}

        #declare T_window2_mat = texture{T_Window rotate z*180}
        #include "bd_window2_o.inc"
        #declare P_window2_3=object{P_def_obj}

        #declare T_window2_mat = texture{T_Window rotate z*270}
        #include "bd_window2_o.inc"
        #declare P_window2_4=object{P_def_obj}

        #declare T_colside1_mat=texture{pigment{image_map{jpeg "bd_colside1" interpolate 2}} finish{ambient 0 diffuse 1}}texture{T_Wall0}
        #include "bd_colside1_o.inc"
        #declare P_colside1=object{ P_Figure_1 }

        #declare T_window1d_mat = texture{T_Window}
        #include "bd_window1d_o.inc"

        #declare T_column1d_mat=texture{pigment{image_map{jpeg "bd_column1door" interpolate 2}} finish{ambient 0 diffuse 1}}texture{T_Wall0}
        #include "bd_column1door_o.inc"
        #declare P_column1door=object{ P_Figure_1 }
        #declare T_door1a_mat = texture{pigment{image_map{jpeg "bd_door1" interpolate 2}} finish{ambient 0 diffuse 1} scale <-1,1,1>}
        #declare T_doorbox_mat =texture{pigment{White*0.8} normal{bumps 0.3} finish{ambient 0 diffuse 0.4 metallic brilliance 2 reflection 0.3*Ref}}
        #declare T_door1b_mat = texture{T_doorbox_mat}
        #include "bd_door1_o.inc"
        #declare P_door1=object{ P_Figure_1 }
        
        #declare T_door2a_mat = texture{pigment{image_map{jpeg "bd_door2" interpolate 2}} finish{ambient 0 diffuse 1}}

        #declare P_metaldoor=pigment{image_map{jpeg "bd_door2d" interpolate 2}}
        #declare T_metaldoor_mat = 
            texture{
                    pigment{P_metaldoor}
                    finish{ambient 0 diffuse 1} 
         }
        #declare T_door2b_mat = texture{T_metaldoor_mat}        
        #include "bd_door2_o.inc"
        #declare P_door2=object{ P_Figure_1 }
        
        #declare T_num1_mat = texture{T_front1_mat finish{diffuse 0.4}}
        #declare T_num2_mat = texture{T_front1_mat finish{diffuse 0.4}}
        #declare T_plate_mat = texture{T_front1_mat}
        #declare T_numcirc_mat = texture{T_front1_mat}
        #include "bd_number_o.inc"
        #declare P_number=object{ P_Figure_1 }
        
        #declare T_mdoortop_mesh_mat = texture{T_front1_mat}
        #include "bd_mdoortop_o.inc"
        #declare P_mdoortop=object{ P_Figure_1 }
        
        #include "bd_mdoor_o.inc"
        #declare P_mdoor=object{ P_Figure_1 }
        
        #declare T_fledge_mat = texture{pigment{image_map{jpeg "bd_mdoorledge" interpolate 2}} finish{ambient 0 diffuse 1}}texture{T_Wall0}
        #include "bd_mdoorledge_o.inc"
        #declare P_mdoorledge=object{ P_Figure_1 }
        
        #declare T_curtain_mat = texture{pigment{rgb <1,0.95,0.94>}finish{ambient 0 diffuse 1}}
        #include "bd_curtain_o.inc"

        #declare Building=union{
            object{ P_glass1d }
            object{ P_door1 }
            object{ P_door2 }
            object{ P_number }
            object{ P_mdoorledge }
            object{ P_mdoor translate <-0.05,-0.35,0>*12.649749/4}
            object{ P_dframe }
            object{ P_column1door }
            object{ P_mdoortop }
        
            object{ P_doortop }
            object{ P_window1d }

            object{P_curtain translate -z*1.1*12.649749/4}
            object{ P_colside1 }
            
            #if (Ref=1) // excludes the glass panes from first pass
                object{ P_glass1}
            #end
            object{ P_window1_left }
            object{ P_bricks1 }
            object{ P_column1 }
            object{ P_corner1 }
            object{ P_front1 }
            object{ P_corner1a }
            object{ P_corner1b }
            object{ P_front1a }
            object{ P_ledge2 }
            object{ P_ledge2w }
            object{ P_window2_1 }
            
            #if (Ref=1) // excludes the glass panes from first pass
                object{ P_glass2}
            #end

            object{ P_column2 }
            object{ P_corner2 }
        
            object{ P_column2b translate x*10}
            object{ P_column2c translate x*20}
            object{ P_column2 scale <-1,1,1> translate x*30}
            object{ P_column2b scale <-1,1,1> translate x*40}
        
            object{ P_column1b translate x*10}
            object{ P_column1c translate x*20}
            object{ P_column1d scale <-1,1,1> translate x*30}
            object{ P_column1 scale <-1,1,1> translate x*40}
        
            object{ P_front1 translate x*10}
            object{ P_front1 translate x*20}
            object{ P_front1 translate x*30}
        
            union{object{P_window2_2}#if (Ref=1)object{P_glass2}#end object{ P_ledge2w } translate x*10}
            union{object{P_window2_3}#if (Ref=1)object{P_glass2}#end object{ P_ledge2w } translate x*20}
            union{object{P_window2_4}#if (Ref=1)object{P_glass2}#end object{ P_ledge2w } translate x*30}
            
            object{P_corner1 scale <-1,1,1> translate x*40}
            object{P_corner1a scale <-1,1,1> translate x*40}
            object{P_corner1b scale <-1,1,1> translate x*40}
            object{P_corner2 scale <-1,1,1> translate x*40}
            
            union{
                object{P_window1_right}
                object{P_curtain translate -z*1.1*12.649749/4}
                #if (Ref=1)  // excludes the glass panes from first pass
                    object{P_glass1}
                #end
                object{P_bricks2}
                translate x*30
            }
            object{ P_colside1 scale <-1,1,1> translate x*30}
            object{ P_colside1 translate x*10}
            object{ P_colside1 scale <-1,1,1> translate x*40}
            
            // these two lines are a hack because the model is only 1 floor high !
            object{ P_front1a translate z*15.5+y*0.5}
            object{ P_ledge2 translate z*15.5+y*0.5}

            rotate x*-90
            scale 4/12.649749
            scale <-1,1,1>
        }
        
        object{Building rotate y*180 translate x*1.5}
        object{Building rotate y*180 scale <1,1,-1> translate -z*11} // mirror building for reflection and radiosity
        
        #declare Sign=union{
            difference{torus{0.95,0.05 rotate x*-90}plane{z,0 inverse}}
            cylinder{-z*0.05,0,0.95}
            cylinder{0,z*0.05,1}
            texture{
                pigment{
                    image_map{
                        jpeg "parkingsign"
                    }
                }
                normal{wrinkles bump_size 0.03 scale 1/50}
                finish{ambient 0 diffuse 0.8 specular 0.8 roughness 1/10}
                translate <-0.5,-0.5,0>
                scale 2
            }                            
            
            translate -z*0.05
            scale <0.3,0.3,0.007/0.05>
        }
        object{Sign translate <9.5,3.4,-0.1>}
        
        // various black boxes (block light)
        box{<-100,-1,0>,<100,0.3,5> texture{pigment{Black}finish{ambient 0 diffuse 0}} translate z*1}
        box{<-100,-1,0>,<100,20,5> texture{pigment{White*0.1}finish{ambient 0 diffuse 1}} translate z*2}
        box{<-100,-1,-2>,<100,25,0> texture{pigment{White*0.1}finish{ambient 0 diffuse 1}} translate -z*13}
    #end
}

//---------------------------------------
// Mini Cooper
//---------------------------------------
#if (MiniOK=1)
    #debug "Mini\n"
    #declare V_WorldBoundMin = <-4.149374, -0.127721, -0.004524>;
    #declare V_WorldBoundMax = <5.696744, 23.635614, 10.148702>;
    #declare C_Paint= rgb <83,106,128>/255;
    #declare C_Paint_Roof = White*0.7;
    #declare C_Paint_Interior = rgb <229,206,157>/255;
    #declare angle_turn=-20; // rotation angle to turn the front wheels left (negative) or right (positive)
    #declare angle_move=30; // forward rotation angle for all the wheels (to be used in animation)
    #declare P_Paint=pigment{image_map{jpeg "car_paint2" interpolate 2}}
    #declare N_Paint=normal{
        average
        normal_map{
            [1 bump_map{jpeg "bd_door2d_bump" interpolate 2}]
            [1 bumps 0.2 scale 0.15]
        }
    }
    #declare T_paint = texture{
        image_pattern{jpeg "bd_door2d_bump" interpolate 2}
        texture_map{
            [0 pigment{P_Paint}normal{N_Paint} finish{ambient 0 diffuse 1 }]
//            [1 pigment{P_Paint} normal{N_Paint} finish{ambient 0 diffuse 0.5 specular 1 roughness 1/1000 reflection {0.1*Ref, 1*Ref falloff 3 exponent 2}}]
            [1 pigment{average pigment_map{[1 P_Paint][2 color C_Paint]}} normal{N_Paint} finish{ambient 0 diffuse 0.5 specular 1 roughness 1/1000 reflection {0.1*Ref, 0.8*Ref falloff 3 exponent 2}}]
        }   
        scale 1
    }
    #declare T_roof = texture{pigment{C_Paint_Roof}finish{ambient 0 diffuse 1 roughness 1/45 specular 1/3 reflection {0.1*Ref, 0.5*Ref}}}
    #declare T_bolts = texture{pigment{White*0.4} finish{ambient 0 diffuse 1 brilliance 1 metallic}}
    #declare T_bottom = texture{pigment{White*0.2} finish{ambient 0 diffuse 1}}
    #declare T_bulb = texture{pigment{Clear}}
    #declare T_chrome = texture{pigment{rgb <1,0.9,0.8>*0.7} finish{ambient 0 diffuse 1 brilliance 5 metallic specular 1 roughness 1/200 reflection{0.4*Ref, 0.99*Ref}}}
    #declare T_chrome = texture{
        pigment{rgb <1,0.9,0.8>*0.7} 
        finish{ambient 0 diffuse 0.7 brilliance 5 metallic specular 1 roughness 1/200 
            reflection{0.2*Ref, 0.6*Ref}
        }
    }
    #declare T_counterface = texture{pigment{Black}finish{reflection 0.2*Ref}}
    #declare T_glass = texture{pigment{rgbf <0.7,0.7,0.7,0.8>} finish{ambient 0 diffuse 0.1 specular 1 roughness 1/1000 reflection{0.1*Ref,0.7*Ref}}}
    #declare T_glass_hlight = texture{
        pigment{image_map{jpeg "headlight" transmit all 0.2 interpolate 2}} 
        normal{bump_map{jpeg "headlight_bmp" interpolate 2} bump_size -2} 
        finish{ambient 0 diffuse 1 specular 0.3 roughness 1/30 reflection {0.2*Ref,0.99*Ref}}
    }
    #declare T_glass_blight = texture{pigment{rgbf <0.8,0.5,0.1,0.3>} finish{ambient 0 diffuse 1 specular 0.3 roughness 1/30 reflection 0.2*Ref}}
    #declare T_interior = texture{pigment{C_Paint_Interior}finish{ambient 0 diffuse 1}}
    #declare T_logo_centre = texture{        
        pigment{image_map{jpeg "mini_emblem" interpolate 2}} 
        finish{ambient 0 diffuse 0.5 reflection 0.2*Ref}
    }
    #declare T_mirror = texture{pigment{Black}finish{reflection 0.99*Ref}}
    #declare T_plastic_black = texture{pigment{White*0.2} finish{ambient 0 diffuse 1 specular 1 roughness 1/15}}
    #declare T_plate = texture{
        pigment{
            image_map{jpeg "lplate" interpolate 2}
        } 
        finish{ambient 0 diffuse 0.6 specular 0.2 roughness 1/15}
    }
    #declare T_plate_rim = texture{T_plastic_black}
    #declare T_rubber = texture{pigment{bozo color_map{[0 White*0.01][1 White*0.3]}} finish{ambient 0 diffuse 1}}
    #declare T_seat = texture{T_interior}
    #declare T_tlbottom = texture{pigment{rgbf <0.8,0.1,0.1,0.3>} finish{ambient 0 diffuse 1 specular 0.3 roughness 1/30 reflection 0.2*Ref}}
    #declare T_tltop = texture{pigment{rgbf <0.8,0.5,0.1,0.3>} finish{ambient 0 diffuse 1 specular 0.3 roughness 1/30 reflection 0.2*Ref}}
    #declare T_wheel = texture{T_chrome}
    
    #declare T_austin_mat = texture{T_chrome}
    #declare T_bl_ch_mat = texture{T_chrome}
    #declare T_bl_gl_mat = texture{T_glass_blight}
    #declare T_bmp_fr_mat = texture{T_chrome}
    #declare T_bmp_rear_mat = texture{T_chrome}
    #declare T_body_mat = texture{T_paint}
    #declare T_body2_mat = texture{T_paint scale 2}
    #declare T_bolts_fr_mat = texture{T_bolts}
    #declare T_bolts_rear_mat = texture{T_bolts}
    #declare T_bottom_fr_mat = texture{T_bottom}
    #declare T_bottom_mat = texture{T_bottom}
    #declare T_bs_bk_mat = texture{T_seat}
    #declare T_bs_bt_mat = texture{T_seat}
    #declare T_bt_ch_mat = texture{T_chrome}
    #declare T_cooper_mat = texture{T_chrome}
    #declare T_cterbase_mat = texture{T_plastic_black}
    #declare T_ctrface_mat = texture{T_counterface}
    #declare T_ctrrim_mat = texture{T_chrome}
    #declare T_dashboard_mat = texture{T_interior}
    #declare T_DEFAULT = texture{T_interior}
    #declare T_dw_rim_mat = texture{T_plastic_black}
    #declare T_dw2_mat = texture{T_chrome}
    #declare T_dw3_mat = texture{T_chrome}
    #declare T_dwshaft_mat = texture{T_plastic_black}
    #declare T_exhaust_mat = texture{T_chrome}
    #declare T_front_mat = texture{T_paint scale 2}
    #declare T_fs_bk_mat = texture{T_seat}
    #declare T_fs_bt_mat = texture{T_seat}
    #declare T_gascap_mat = texture{T_chrome}
    #declare T_gl_fr_mat = texture{T_glass}
    #declare T_gl_rear_mat = texture{T_glass}
    #declare T_gl_side1_mat = texture{T_glass}
    #declare T_gl_side2_mat = texture{T_glass}
    #declare T_gr_bk_mat = texture{T_paint}
    #declare T_gr_fr1_mat = texture{T_paint}
    #declare T_gr_fr2_mat = texture{T_paint}
    #declare T_handle_mat = texture{T_chrome}
    #declare T_hinge1_mat = texture{T_paint}
    #declare T_hinge2_mat = texture{T_paint}
    #declare T_hinge3_mat = texture{T_paint}
    #declare T_hinge4_mat = texture{T_paint}
    #declare T_hl_bulb_mat = texture{T_mirror}
    #declare T_hl_ch_mat = texture{T_chrome}
    #declare T_hl_gl_mat = texture{T_glass_hlight}
    #declare T_hl_mir_mat = texture{T_mirror}
    #declare T_hood_mat = texture{T_paint scale 2}
    #declare T_hoodtop_mat = texture{T_paint}
    #declare T_i_body1_mat = texture{T_interior}
    #declare T_i_body2_mat = texture{T_interior}
    #declare T_i_fl_rear_mat = texture{T_bottom}
    #declare T_i_floor_fr_mat = texture{T_bottom}
    #declare T_i_floor_mat = texture{T_interior}
    #declare T_i_floor2_mat = texture{T_interior}
    #declare T_i_handle1_mat = texture{T_chrome}
    #declare T_i_handle2_mat = texture{T_chrome}
    #declare T_i_handle3_mat = texture{T_chrome}
    #declare T_i_rear_mat = texture{T_interior}
    #declare T_i_roof_mat = texture{T_interior}
    #declare T_i_rv_mat = texture{T_chrome}
    #declare T_i_rvmir_mat = texture{T_mirror}
    #declare T_lgcentre_mat = texture{T_logo_centre}
    #declare T_lgwings_mat = texture{T_chrome}
    #declare T_lwip1_mat = texture{T_chrome}
    #declare T_lwip2_mat = texture{T_chrome}
    #declare T_pedal1_mat = texture{T_plastic_black}
    #declare T_pedal2_mat = texture{T_plastic_black}
    #declare T_pl_fr_mat = texture{T_plate}
    #declare T_pl_frrim_mat = texture{T_plastic_black}
    #declare T_pl_rear_mat = texture{T_plate}
    #declare T_pl_rrim_mat = texture{T_plastic_black}
    #declare T_radiator_mat = texture{T_chrome}
    #declare T_rear_hd_mat = texture{T_chrome}
    #declare T_rear_hinge_mat = texture{T_paint}
    #declare T_rear_mat = texture{T_paint}
    #declare T_roof_mat = texture{T_roof}
    #declare T_roof_trim_mat = texture{T_paint}
    #declare T_rv_side_mat = texture{T_chrome}
    #declare T_rv_sidemir_mat = texture{T_mirror}
    #declare T_rwip1_mat = texture{T_chrome}
    #declare T_rwip2_mat = texture{T_chrome}
    #declare T_sprinkler_mat = texture{T_plastic_black}
    #declare T_switch_mat = texture{T_plastic_black}
    #declare T_throthead_mat = texture{T_plastic_black}
    #declare T_throtrub_mat = texture{T_plastic_black}
    #declare T_throtshaft_mat = texture{T_chrome}
    #declare T_tl_ch_mat = texture{T_chrome}
    #declare T_tl_glbt_mat = texture{T_tlbottom}
    #declare T_tl_gltop_mat = texture{T_tltop}
    #declare T_tyre_fr_mat = texture{T_rubber}
    #declare T_tyre_rear_mat = texture{T_rubber}
    #declare T_wd_ch1_mat = texture{T_chrome}
    #declare T_wd_ch2_mat = texture{T_chrome}
    #declare T_wd_ch3_mat = texture{T_chrome}
    #declare T_wd_chbk_mat = texture{T_chrome}
    #declare T_wd_chfr_mat = texture{T_chrome}
    #declare T_wh_fr1_mat = texture{T_chrome}
    #declare T_wh_fr2_mat = texture{T_chrome}
    #declare T_wh_fr3_mat = texture{T_chrome}
    #declare T_wh_rear1_mat = texture{T_chrome}
    #declare T_wh_rear2_mat = texture{T_chrome}
    #declare T_wh_rear3_mat = texture{T_chrome}
    
    #include "mini_mesh_o.inc"
    #declare FrontWheel=union{
        object{ P_tyre_fr }
        object{ P_bolts_fr }
        object{ P_wh_fr3 }
        object{ P_wh_fr2 }
        object{ P_wh_fr1 }
    }
    #declare RearWheel=union{
        object{ P_wh_rear1 }
        object{ P_wh_rear2 }
        object{ P_wh_rear3 }
        object{ P_bolts_rear }
        object{ P_tyre_rear }
    }
       
    #declare Halfcar=union{
        
        union{
            object{ P_body }
            object{ P_hood }
            object{ P_rear }
            object{ P_body2 }
            object{ P_front }
            object{ P_hoodtop }
            object{ P_gr_bk }
            object{ P_gr_fr1 }
            object{ P_gr_fr2 }
            object{ P_rear_hinge }
            object{ P_hinge1 }
            object{ P_roof_trim }
            object{ P_hinge2 }
            object{ P_hinge4 }
            object{ P_hinge3 }
//            interior{ior 10}
        }
        object{ P_i_fl_rear }
        object{ P_i_floor }
        object{ P_i_floor_fr }
        object{ P_dashboard }
        object{ P_roof }
        object{ P_sprinkler }
        object{ P_radiator }
        object{ P_handle }
        object{ P_wd_ch1 }
        object{ P_wd_ch2 }
        object{ P_wd_ch3 }
        object{ P_wd_chfr }
        object{ P_wd_chbk }
        object{ P_bt_ch }
        object{ P_hl_gl }
        object{ P_hl_ch }
        object{ P_hl_bulb }
        object{ P_hl_mir }
        object{ P_bmp_fr }
        object{ P_bottom }
        object{ P_bottom_fr }
        object{ P_gascap }
        object{ P_tl_ch }
        object{ P_bmp_rear }
        object{ P_bl_gl }
        object{ P_bl_ch }
        
        #if (Ref=1) // excludes the glass panes from first pass
            object{ P_gl_fr }
            object{ P_gl_rear }
            object{ P_gl_side1 }
            object{ P_gl_side2 }
        #end
        
        object{ P_rv_side }
        object{ P_rv_sidemir }
        object{ P_rear_hd }
        object{ P_i_roof }
        object{ P_bs_bt }
        object{ P_fs_bk }
        object{ P_bs_bk }
        object{ P_i_rear }
        object{ P_i_body1 }
        object{ P_i_body2 }
        object{ P_fs_bt }
        object{ P_i_handle1 }
        object{ P_i_handle3 }
        object{ P_pedal2 }
        object{ P_pedal1 }
        object{ P_i_handle2 }
        object{ P_tl_gltop }
        object{ P_tl_glbt }
    }
    
    
    #declare MiniCooper=union{
        object{Halfcar}
        object{Halfcar scale <-1,1,1>}
        
        object{ P_exhaust }
        object{ P_switch }
        object{ P_i_rv }
        object{ P_i_rvmir }
        object{ P_dw_rim }
        object{ P_dw2 }
        object{ P_dw3 }
        object{ P_dwshaft }
        object{ P_throthead }
        object{ P_throtshaft }
        object{ P_throtrub }
        object{ P_lwip1 }
        object{ P_lwip2 }
        object{ P_rwip1 }
        object{ P_rwip2 }
        object{ P_cterbase }
        object{ P_ctrrim }
        object{ P_ctrface }
        object{ P_lgwings }
        object{ P_lgcentre }
        object{ P_pl_frrim }
        object{ P_pl_fr }
        object{ P_austin }
        object{ P_cooper }
        object{ P_pl_rrim }
        object{ P_pl_rear }
        object{ FrontWheel translate <-4.8,-4,-2> rotate x*angle_move rotate z*angle_turn translate <4.8,4,2>}
        object{ FrontWheel translate <-4.8,-4,-2> rotate x*(10+angle_move) rotate -z*angle_turn translate <4.8,4,2> scale <-1,1,1>}
        object{ RearWheel translate <-4.8,-19.5,-2> rotate x*(42+angle_move) translate <4.8,19.5,2>} 
        object{ RearWheel translate <-4.8,-19.5,-2> rotate x*(-10+angle_move) translate <4.8,19.5,2> scale <-1,1,1>} 

        rotate x*-90
        translate z*V_WorldBoundMax.y/2
        
        scale 1.4/10.148702
        scale <-1,1,1>
        rotate y*180
        
    }
    object{MiniCooper rotate y*-90 translate car_location}

#end
         
         
         
         
//------------------------------------------------------------------------------------------FIN DEL CODIGO DEL COCHE, ACERA E EDIFICIO---------------------------------------------------------



//------------------------------------------------------------------------------------------COMIENZO DEL CODIGO DE LA FAROLA-------------------------------------------------------------------

#include "colors.inc"

#declare yPostMast=7.5; // Height of the main mast
#declare rLampSupport=2.5; // radius of the lamp support
#declare yStopLightSupport=1.5; // height of the stoplight branch
#declare zStopLightSupport=4;  // length of the stoplight branch
#declare yStopLightRig=4.25;  
#declare yDontWalkRig=2.33;  

//--------------------------------------
// Textures
//--------------------------------------
#declare C_Paint=rgb<255,206,67>/255;
#declare T_StopLight=texture{
        pigment{
                bozo
                color_map{
                        [0 color C_Paint]
                        [1 color C_Paint*0.7]
                }
        }                                
        normal{bozo 0.7 scale 2}
        finish{ambient 0 diffuse 0.6 specular 0.3 roughness 0.1}
        scale 0.5

}
//--------------------------------------
// Texture mast
//--------------------------------------
#declare C_Post=rgb<1,0.8,0.7>;
#declare C_Post=rgb<197,213,209>/255;
#declare T_NYPostAttach=texture{
        pigment{C_Post*1.2}
        finish{ambient 0  brilliance 3 diffuse 0.6 metallic specular 0.70 roughness 1/60 reflection 0.05}
}
#declare T_NYPost0=texture{
        pigment{
                crackle solid
                color_map{
                        [0 color C_Post*0.7*0.1]
                        [1 color C_Post*1.5*0.1]
                }
                
        }                              
        finish{ambient 0  brilliance 3 diffuse 0.4 metallic specular 0.70 roughness 1/60 reflection 0.01}
}
#declare T_NYPost1=texture{
        pigment{
                bozo turbulence 0.3
                color_map{
                        [0 color C_Post*0.7*0.2]
                        [1 color C_Post*1.5*0.2]
                }
                
        }                              
        normal{granite bump_size 0.01 scale 0.1}
        finish{ambient 0  brilliance 3 diffuse 0.4 metallic specular 0.70 roughness 1/60}
}
#declare T_NYPost2=texture{
        pigment{
                bozo turbulence 0.3
                color_map{
                        [0 color C_Post*0.8]
                        [1 color C_Post*1.7]
                }
                scale 3
                
        }
        normal{granite bump_size 0.1 scale 0.05}
        finish{ambient 0  brilliance 3 diffuse 0.4 metallic specular 0.70 roughness 1/60 }
}                  
#declare T_NYPost3=texture{
        pigment{
                bozo turbulence 0.3
                color_map{
                        [0 color C_Post*0.8]
                        [1 color C_Post*1.7]
                }
                scale 3
                
        }
        normal{granite bump_size 0.1 scale 0.05}
        finish{ambient 0  brilliance 3 diffuse 0.4 metallic specular 0.70 roughness 1/60 reflection 0.25}
}                  
#declare T_NYPost=texture{
        gradient y
        poly_wave 0.2
        texture_map{
                [0 T_NYPost1 scale 0.01]
                [1 T_NYPost3 scale 0.01]
        }
        scale (yPostMast+rLampSupport)*1.1
}

#declare M_Glass=material{
        texture{pigment{rgbf <0.5,0.5,0.5,0.9>} finish{ambient 0 diffuse 0.1 specular 1 roughness 0.001 reflection 0.3}}
        interior{ior 1.45}
}
//--------------------------------------
// Mat
//--------------------------------------
#declare PostBase=union{
        object{#include "postbase.inc"}
        union{
                superellipsoid{<0.3,0.3> scale <1,0.3,0.1>}
                superellipsoid{<0.3,0.3> scale <1,0.3,0.1> rotate y*90}
                scale 0.37*<1,2,1> translate -y*0.2
                translate y
        }
        texture{
                gradient y
                texture_map{
                        [0 T_NYPost0 scale 0.02]
                        [1 T_NYPost2 scale 0.02]
                }
                scale 2
        }
}

#declare PostMast=union{
        object{#include "postmast.inc" rotate y*20 scale <0.26,yPostMast,0.26>}
        union{
                sphere{0,0.1 scale <1,0.4,1>}
                sphere{0,0.075 scale <1,1,1> translate y*0.01}
                sphere{0,0.1 scale <1,0.4,1> translate -y*0.2}
                cylinder{0,-y*0.2,0.08}
                translate y*yPostMast
        }
}       
//--------------------------------------
// Joint
//--------------------------------------
#macro Joint(rj)
        union{
                cylinder{-y*0.13,y*0.13,rj}
                torus{rj,0.025 scale <1.2,1,1.2> translate y*0.15}
                sphere{0,0.5 scale <0.04,0.04,rj*2> rotate y*45 translate y*0.075}
                sphere{0,0.5 scale <0.04,0.04,rj*2> rotate -y*45 translate y*0.075}
                sphere{0,0.5 scale <0.04,0.04,rj*2> rotate y*90 translate y*0.075}
                torus{rj,0.025}
                sphere{0,0.5 scale <0.04,0.04,rj*2> rotate y*45 translate -y*0.075}
                sphere{0,0.5 scale <0.04,0.04,rj*2> rotate -y*45 translate -y*0.075}
                sphere{0,0.5 scale <0.04,0.04,rj*2> rotate y*90 translate -y*0.075}
                torus{rj,0.025 scale <1.2,1,1.2> translate -y*0.15}
        }
#end                    
//--------------------------------------
// Lamp
//--------------------------------------
#declare Lamp=union{ 
        object{#include "postlamp.inc" scale <1,1,-1.2> translate -z*0.1}
        sphere{0,1 scale 0.4 scale <0.8,0.8,1.2> translate <0,-0.2,1.7> material{M_Glass}}
}                          
//--------------------------------------
// Lamp support
//--------------------------------------
#declare LampSupport=union{
        difference{
                torus{rLampSupport,0.04 rotate z*90}
                plane{y,0}
                plane{z,0 inverse}
        }
        object{Lamp scale 0.4 translate <0,rLampSupport-0.045,0>}
        union{
                cylinder{0,-y*0.25,0.05}
                sphere{0,0.1 scale <1,0.3,1> translate -0.05*y}
                cylinder{-0.05*y,-0.2*y,0.08}
                sphere{0,0.1 scale <1,0.3,1> translate -0.2*y}
                translate -z*rLampSupport
        }                             
        translate z*(rLampSupport+0.15)
}                               
                             

//--------------------------------------
// DogSign
//--------------------------------------
#declare NYDogSign=union{
        superellipsoid{<0.1,0.1> translate z}
        superellipsoid{<0.1,0.1> 
                texture{
                        pigment{image_map{jpeg "ny_dog_sign" once}}
                        finish{ambient 0 diffuse 0.7 specular 0.1 roughness 0.1}
                        scale <2,2,1>
                        translate <-1,-1,0>
                        }
        }                
        scale <250,340,1>*0.42/250
}                
             
//--------------------------------------
// Keep Clear
//--------------------------------------
#declare NYKeepClear=union{
        superellipsoid{<0.1,0.1> translate z}
        superellipsoid{<0.1,0.1> 
                texture{
                        pigment{image_map{jpeg "ny_keep_sign" once}}
                        finish{ambient 0 diffuse 0.7 specular 0.1 roughness 0.1}
                        scale <2,2,1>
                        translate <-1,-1,0>
                        }
        }                
        scale <122,126,1>*0.41/122
}                
//--------------------------------------
// FDR Drive
//--------------------------------------
#declare NYFDRSign=union{
        superellipsoid{<0.1,0.1> translate z}
        superellipsoid{<0.1,0.1> 
                texture{
                        pigment{image_map{jpeg "ny_fdr_sign" once}}
                        finish{ambient 0 diffuse 0.7 specular 0.1 roughness 0.1}
                        scale <2,2,1>
                        translate <-1,-1,0>
                        }
        }                
        scale <245,199,1>*0.63/245
}                

//--------------------------------------
// Loupiotte
//--------------------------------------
#declare Loupiotte=union{
        #declare rmast=0.112;
        union{
                cylinder{0,z*0.3,0.03}
                difference{torus{0.1,0.03 rotate z*90} plane{y,0 inverse}plane{z,0} translate <0,0.1,0.3>}
                union{
                        union{
                                difference{sphere{0,1}plane{y,0 inverse}}
                                torus{1,0.2}
                                scale <0.08,0.06,0.08>
                        }
                        merge{
                                cone{0,0.08,y*0.2,0.06}
                                sphere{0,0.06 translate y*0.2}
                                material{
                                        texture{
                                                pigment{
                                                        color rgbt <0.878,0.455,0.11,0.1>*1.7
                                                        
                                                }
                                                finish{
                                                        ambient 0 diffuse 0.2 specular 0.1 roughness 0.1
                                                }
                                        }
                                        interior{
                                                ior 1.33
                                        }
                                }
                        }
                        translate <0,0.15,0.4>
                }                                    
                sphere{0,0.035}
                translate z*rmast
        }
        union{
                difference{
                        cylinder{-y*0.14,y*0.14,rmast}
                        plane{z,0}
                }
                sphere{0,0.025 translate <0,0.112,rmast> rotate y*60}
                sphere{0,0.025 translate <0,0.112,rmast> rotate -y*60}
                sphere{0,0.025 translate <0,-0.112,rmast> rotate y*60}
                sphere{0,0.025 translate <0,-0.112,rmast> rotate -y*60}
        }
}
//--------------------------------------
// Basic post
//--------------------------------------
#declare NYPost=union{
        object{PostBase scale <0.56,0.6,0.56> rotate y*90}
        object{PostMast}
        object{LampSupport translate <0,yPostMast,0>}
}                           

//--------------------------------------
// Poste
//--------------------------------------
#declare NYPost_1=union{
        object{NYPost}
        object{NYDogSign rotate z*2 translate <0,3.5,-0.14> rotate y*75}
        object{NYFDRSign rotate -z*0.5 translate <-0.1,6.5,-0.14> rotate y*80}
        object{Loupiotte translate y*5 rotate y*170}
}



#declare luz = light_source {
	<-6.25, 9.5, 1>
	color rgb 5
	spotlight  
	point_at <-6.25,0,1>
    fade_power 5 fade_distance 30
    tightness 20
    
}

#declare bombilla = sphere {
	<-6.25, 9.9, 1>, 0.05
	texture {
		pigment {
			color rgbf <1, 1, 1, .5>
		}
		finish {
		    ambient 1
		}		
	}
}

#declare postlamp = union {
    object {luz}
    object {bombilla}
}




#declare poste = object {
    NYPost_1 texture{T_NYPost} rotate y*-90 translate <-3,0,1> 
} 

#declare farola = union {
    object {poste}
    object {postlamp}
}

object {farola rotate y*-90 translate <8,0.25,-0.5> scale 0.375 }   
object {farola rotate y*-90 translate <30,0.25,-0.5> scale 0.375 }
object {farola rotate y*-90 translate <45,0.25,-0.5> scale 0.375 }

      

   
//------------------------------------------------------------------------FIN DEL CODIGO DE LA FAROLA-------------------------------------------------------------------


//------------------------------------------------------------------------COMIENZO DEL CODIGO DE LAS CAJAS--------------------------------------------------------------


#macro mNewsVM(xVMBox,yVMBox,zVMBox,rtyVMBox,eVM,T_PaintHead,T_PaintBox,T_NewsTop,T_NewsFront,T_NewsBottom)
// xVMBox, yVMBoxn, ZVMBox = size of the box containing the papers
// rtMBox : ratio between the bottom part of the box (usually with the newspaper name) and the middle part (with the paper of the day)
// eVM : thickness of the box walls
// T_PaintHead : texture of the head (where you put the money)
// T_PaintBox : texture of the box                            
// T_NewsTop : image map for the head (instructions)
// T_NewsFront : image map for the newspaper
// T_NewsBottom : image map for the bottom of the box

#local xVMHead=xVMBox*0.5;
#local yVMHead=xVMHead/0.7;
#local zVMHead=xVMHead;
#local VMHead=union{
    union{
//                box{0,1 translate -x*0.5 scale <xVMHead/(xVMHead+2*eVM),yVMHead/(yVMHead+eVM),zVMHead/(zVMHead+5*eVM)> translate z*4*eVM} // box
        superellipsoid{<0.1,0.1> scale 0.5 translate <0,0.5,0.5> scale <xVMHead/(xVMHead+2*eVM),yVMHead/(yVMHead+eVM),zVMHead/(zVMHead+5*eVM)> translate z*4*eVM} // box
        cylinder{-0.5*x,x*0.5,1/30 scale <1,1,2> translate <0,29/30,0>}
        union{
            difference{
                box{<-0.5,0,1/3>,<0.5,1,1>}
                plane{z,0 rotate -x*15 translate <0,2/3,1/3>}
                    
            }                        
            difference{
                cylinder{-0.5*x,x*0.5,1/3}
                plane{z,0 inverse}
                plane{y,0 inverse}
                translate <0,1,1/3>
            }
        }
        scale <xVMHead,yVMHead,zVMHead>     
    }                
    box{0,1 texture{T_NewsTop} translate -x*0.5 scale <xVMHead*0.8,yVMHead*0.4,-eVM> translate <0,yVMHead*0.6-eVM*2,1.9*eVM>}
    #declare rC=zVMHead/15;
    difference{
        cone{0,1,x*0.5,0.8}
        cylinder{-x,x*1.1,0.7}
        scale rC
        translate <xVMHead*0.5,rC*3,zVMHead*2/3>
    }
    difference{
        cone{0,1,x*0.5,0.8}
        cylinder{-x,x*1.1,0.7}
        scale rC
        translate <xVMHead*0.5,rC*3,zVMHead*2/3>
        scale <-1,1,1>
    }
    difference{
        cone{0,1,z*0.5,0.8}
        cylinder{-z,z*1.1,0.7}
        scale rC*0.8
        rotate y*180
        translate <0,yVMHead*2/3,eVM>
    }
}                       
#local VMSides=union{
    box{0,<eVM,yVMBox,zVMBox> translate <-xVMBox/2,0,0>}  // left
    box{0,<eVM,yVMBox,zVMBox> translate <-xVMBox/2,0,0> scale <-1,1,1>} // right
    box{0,1 translate -x*0.5 scale <xVMBox,eVM,zVMBox> translate y*yVMBox} // top
    union{
        union{                // left upper round corner
            difference{cylinder{0,z,1}plane{y,0}plane{x,0 inverse}}
            box{0,1 scale <-1,-3,1>}
            scale <eVM*0.5,eVM,zVMBox>
            translate -x*xVMBox*0.5
        }
        union{                  // right upper round corner
            difference{cylinder{0,z,1}plane{y,0}plane{x,0 inverse}}
            box{0,1 scale <-1,-3,1>}
            scale <eVM*0.5,eVM,zVMBox>
            translate -x*xVMBox*0.5
            scale <-1,1,1>
        }
        translate y*yVMBox     
    }
    box{0,1 translate -x*0.5 scale <xVMBox,yVMBox,eVM> scale <1,1,-1> translate z*(zVMBox-eVM)}
}
#local xVMFront=xVMBox*xVMBox/(xVMBox+3*eVM);
//#warning concat(str(xVMBox+3*eVM,0,3),"\n")
//#warning concat(str(xVMFront,0,3),"\n")
#local yVMFront=rtyVMBox*yVMBox;
#local eVMFront1=xVMBox*0.18/1.4;
#local eVMFront2=eVMFront1*0.4;
#local yVMBottom=yVMBox-yVMFront;
#local VMFront=union{
    // Outer frame
    box{0,1 translate -x*0.5 scale <xVMFront,eVMFront1,eVM>}
    box{0,1 translate -x*0.5 scale <xVMFront,eVMFront1,eVM> scale <1,-1,1> translate y*yVMFront}
    box{0,1 scale <eVMFront1,yVMFront-2*eVMFront1,eVM> translate <-xVMFront*0.5,eVMFront1,0>}
    box{0,1 scale <eVMFront1,yVMFront-2*eVMFront1,eVM> translate <-xVMFront*0.5,eVMFront1,0> scale <-1,1,1>}
    
    // Inner frame
    box{0,1 translate -x*0.5 scale <xVMFront-2*(eVMFront1-eVMFront2),-eVMFront2,-eVM> translate y*eVMFront1}
    box{0,1 translate -x*0.5 scale <xVMFront-2*(eVMFront1-eVMFront2),-eVMFront2,-eVM> scale <1,-1,1> translate y*(yVMFront-eVMFront1)}
    box{0,1 scale <-eVMFront2,yVMFront-2*(eVMFront1-eVMFront2),-eVM> translate <-xVMFront*0.5+eVMFront1,eVMFront1-eVMFront2,0>}
    box{0,1 scale <-eVMFront2,yVMFront-2*(eVMFront1-eVMFront2),-eVM> translate <-xVMFront*0.5+eVMFront1,eVMFront1-eVMFront2,0> scale <-1,1,1>}
    
    // Center pane
    box{0,1 texture{T_NewsFront} translate -x*0.5 scale <xVMFront-2*eVMFront1,yVMFront-2*eVMFront1,eVM> translate y*eVMFront1}
    
    // Hinges
    union{
        cylinder{-x*4/6,-x*2/6,1}
        cylinder{x*2/6,x*4/6,1}
        scale <xVMFront*0.5,2*eVM,2*eVM>
        translate -y*2*eVM
    }
    translate y*yVMBottom
}       
#declare yVMBPane=yVMBottom-2*eVMFront1;
#declare VMBottom=union{
    //Hinges
    union{
        cylinder{-x,-x*0.9*4/6,1}
        cylinder{-x*0.9*2/6,x*0.9*2/6,1}
        cylinder{x,x*0.9*4/6,1}
        scale <xVMFront*0.5,2*eVM,2*eVM>
        translate y*(yVMBottom-2*eVM)
    }    
    cylinder{-x,x,1 scale <xVMFront*0.5,eVMFront1*0.5,eVM> translate y*(yVMBottom-2*eVM-eVMFront1*0.5)}
    // Frame                                                  
    union{
        box{0,1 scale <eVMFront2,yVMBPane,eVM> translate -xVMFront*0.5*x}
        box{0,1 scale <eVMFront2,yVMBPane,eVM> translate -xVMFront*0.5*x scale <-1,1,1>}
        box{0,1 translate -x*0.5 scale <xVMFront,eVMFront2,eVM>}
        box{0,1 translate -x*0.5 scale <xVMFront,eVMFront2,eVM> scale <1,-1,1> translate y*yVMBPane}
        translate y*eVMFront1
    }                
    // Center pane
    box{0,1 texture{T_NewsBottom} translate -x*0.5 scale <xVMFront-2*eVMFront2,yVMBPane-2*eVMFront2,eVM> translate <0,(eVMFront1+eVMFront2),eVM>}
    // Bottom bar
    cylinder{-x,x,1 scale <xVMFront*0.5,eVMFront1*0.5,eVM*2> translate y*eVMFront1*0.5}
    
//        box{0,1 translate -x*0.5 scale <xVMFront,yVMBottom,eVM>}
    
}
#local xVMHandle=xVMHead*2.5/7;
#local yVMHandle=xVMHandle*6/2.5;
#local zVMHandle=6*eVM;
#local rVMHandle=1.5*eVM;
#local rVMHandle2=xVMHandle*0.4;
#local VMHandle=union{
    box{<0,0,-1>,1 translate -x*0.5 scale <xVMHandle,yVMHandle,-zVMHandle>}
    union{                                                    
        cylinder{-x,x,rVMHandle scale <xVMHandle*0.5,1,1> translate y*2*rVMHandle2}
        difference{torus{rVMHandle2,rVMHandle rotate x*90} plane{x,0 inverse} translate <-xVMHandle*0.5,rVMHandle2,0>}
        difference{torus{rVMHandle2,rVMHandle rotate x*90} plane{x,0 inverse} translate <-xVMHandle*0.5,rVMHandle2,0> scale <-1,1,1>}
        rotate -x*75 // you can change the handle angle here
        translate <0,yVMHandle-2*rVMHandle,-zVMHandle*0.5>
    }       
    translate y*(yVMBox-yVMHandle*0.25)
}
#local VMBox=union{
    object{VMSides}
    union{
        object{VMFront}
        object{VMBottom}
        object{VMHandle}
        translate z*eVM*5
    }
}
union{
    object{VMHead texture{T_PaintHead scale yVMHead} translate <0,yVMBox,rVMHandle*2>}
    object{VMBox texture{T_PaintBox scale yVMBox+yVMHandle}}
    
}
#end


// =========================================
// Examples
// -----------------------------------------

#include "colors.inc"

#declare xVMBox=0.5;
#declare yVMBox=xVMBox*3/1.4;
#declare zVMBox=0.5;
#declare yrtVMBox=0.6;
#declare eVM=0.005;
#declare C_NVM=rgb<1,0.6,0.05>; // yellow
#declare F_Newspaper= finish{ambient 0 diffuse 0.6}
#declare T_NewsTop=texture{pigment{image_map{png "newsmap_2"}} finish{F_Newspaper}}
#declare T_NewsFront=texture{T_NewsTop} // should be different
#declare T_NewsBottom=texture{T_NewsTop} // should be different
#declare N_NVM=normal{bozo 0.2 scale 0.4}
#declare F_NVM=finish{ambient 0 diffuse 0.7 specular 0.01 roughness 0.001 reflection 0.1}
#declare T_PaintHead=texture{pigment{gradient y color_map{[0 C_NVM*0.5][1 C_NVM]}} normal{N_NVM} finish{F_NVM}}
#declare T_PaintBox=texture{pigment{gradient y color_map{[0 C_NVM*0.5][1 C_NVM]}} normal{N_NVM} finish{F_NVM}}

#declare NVM2=object{mNewsVM(xVMBox,yVMBox,zVMBox,yrtVMBox,eVM,T_PaintHead,T_PaintBox,T_NewsTop,T_NewsFront,T_NewsBottom)}

#declare xVMBox=0.49;
#declare yVMBox=xVMBox*2.5/1.4;
#declare zVMBox=0.45;
#declare yrtVMBox=0.64;
#declare C_NVM=rgb<1,0.1,0.05>*0.8; // red
#declare C_NVM2=rgb<1,0.95,0.85>;
#declare T_PaintHead=texture{pigment{gradient y color_map{[0 C_NVM2*0.5][1 C_NVM2]}} normal{N_NVM} finish{F_NVM}}
#declare T_PaintBox=texture{pigment{gradient y color_map{[0 C_NVM*0.5][1 C_NVM]}} normal{N_NVM} finish{F_NVM}}
#declare NVM3=object{mNewsVM(xVMBox,yVMBox,zVMBox,yrtVMBox,eVM,T_PaintHead,T_PaintBox,T_NewsTop,T_NewsFront,T_NewsBottom)}

#declare xVMBox=0.40;
#declare yVMBox=xVMBox*3.2/1.4;
#declare zVMBox=0.4;
#declare yrtVMBox=0.63;
#declare C_NVM=rgb<0.141,0.9,0.25>*0.8; // green
#declare T_PaintHead=texture{pigment{gradient y color_map{[0 C_NVM*0.5][1 C_NVM]}} normal{N_NVM} finish{F_NVM}}
#declare T_PaintBox=texture{pigment{gradient y color_map{[0 C_NVM*0.5][1 C_NVM]}} normal{N_NVM} finish{F_NVM}}
#declare NVM4=object{mNewsVM(xVMBox,yVMBox,zVMBox,yrtVMBox,eVM,T_PaintHead,T_PaintBox,T_NewsTop,T_NewsFront,T_NewsBottom)}


// -----------------------------------------
// USA Today vending machine
// -----------------------------------------

#declare xV=1.75;
#declare yV=xV*1.4/1.75;
#declare rC=0.15;
#declare eV=0.07;
#declare zV=yV;
#declare yF=xV*2.6/1.75;
#declare rC2=rC+eV;
#declare xF=xV*0.5/1.75;
#declare T_VMHead=texture{
    pigment{rgb<0.93,0.92,0.912>}
    finish{ambient 0 diffuse 0.5 specular 0.01 roughness 0.01}
}

#declare T_VMFoot=texture{
    pigment{
        crackle solid
        turbulence 0.3
        scale 1/4
        color_map{
            [0 rgb<0.93,0.92,0.912>*0.1]
            [1 rgb<0.93,0.92,0.912>*0.2]
        }
    }
    normal{bozo 0.2}
    finish{ambient 0 diffuse 0.8 specular 0.4 roughness 1/20}
}                    
#declare T_USAToday=texture{
    pigment{image_map{gif "logo"}}
    normal{bozo 0.2}
    finish{ambient 0 diffuse 0.8 specular 0.1 roughness 0.05 }
}                       
#declare USAToday=box{0,1 texture{T_USAToday} translate <-0.5,-0.5,0> scale <213,142,1>/213}
#declare NVM_UT=union{
    // Head
    union{
        difference{cylinder{0,zV*z,rC2}cylinder{-z*0.1,zV*z*1.1,rC}plane{x,0 inverse}plane{y,0} translate <-xV/2,yV/2,0>}
        difference{cylinder{0,zV*z,rC2}cylinder{-z*0.1,zV*z*1.1,rC}plane{x,0}plane{y,0} translate <xV/2,yV/2,0>}
        difference{cylinder{0,zV*z,rC2}cylinder{-z*0.1,zV*z*1.1,rC}plane{x,0 inverse}plane{y,0 inverse} translate <-xV/2,-yV/2,0>}
        difference{cylinder{0,zV*z,rC2}cylinder{-z*0.1,zV*z*1.1,rC}plane{x,0}plane{y,0 inverse} translate <xV/2,-yV/2,0>}
        box{0,<xV,eV,zV> translate <-xV/2,yV/2+rC,0>}
        box{0,<xV,eV,zV> translate <-xV/2,yV/2+rC,0> scale <1,-1,1>}
        box{0,<eV,yV,zV> translate <xV/2+rC,-yV/2,0>}
        box{0,<eV,yV,zV> translate <xV/2+rC,-yV/2,0> scale <-1,1,1>}
        object{USAToday rotate z*45 scale xV/2 rotate y*90 translate <-xV/2-rC-eV*1.01,0,zV/2>}
        
        union{
            difference{torus{rC+eV/2,eV/2 rotate x*-90}plane{x,0 inverse}plane{y,0} translate <-xV/2,yV/2,0>}
            difference{torus{rC+eV/2,eV/2 rotate x*-90}plane{x,0}plane{y,0} translate <xV/2,yV/2,0>}
            difference{torus{rC+eV/2,eV/2 rotate x*-90}plane{x,0 inverse}plane{y,0 inverse} translate <-xV/2,-yV/2,0>}
            difference{torus{rC+eV/2,eV/2 rotate x*-90}plane{x,0}plane{y,0 inverse} translate <xV/2,-yV/2,0>}
            cylinder{0,y*yV,eV/2 translate <-xV/2-eV/2-rC,-yV/2,0>}
            cylinder{0,y*yV,eV/2 translate <xV/2+eV/2+rC,-yV/2,0>}
            cylinder{0,x*xV,eV/2 translate <-xV/2,yV/2+eV/2+rC,0>}
            cylinder{0,x*xV,eV/2 translate <-xV/2,-yV/2-eV/2-rC,0>}
            scale <1,1,3>
            texture{pigment{Black} finish{ambient 0 diffuse 0 specular 0.3 roughness 0.01 }}
        }

        union{
            difference{torus{rC+eV/2,eV/2 rotate x*-90}plane{x,0 inverse}plane{y,0} translate <-xV/2,yV/2,0>}
            difference{torus{rC+eV/2,eV/2 rotate x*-90}plane{x,0}plane{y,0} translate <xV/2,yV/2,0>}
            difference{torus{rC+eV/2,eV/2 rotate x*-90}plane{x,0 inverse}plane{y,0 inverse} translate <-xV/2,-yV/2,0>}
            difference{torus{rC+eV/2,eV/2 rotate x*-90}plane{x,0}plane{y,0 inverse} translate <xV/2,-yV/2,0>}
            cylinder{0,y*yV,eV/2 translate <-xV/2-eV/2-rC,-yV/2,0>}
            cylinder{0,y*yV,eV/2 translate <xV/2+eV/2+rC,-yV/2,0>}
            cylinder{0,x*xV,eV/2 translate <-xV/2,yV/2+eV/2+rC,0>}
            cylinder{0,x*xV,eV/2 translate <-xV/2,-yV/2-eV/2-rC,0>}
            union{
                box{<-xV/2-rC-eV/2,-yV/2,0>,<xV/2+rC+eV/2,yV/2,eV>}
                box{<-xV/2,-yV/2-rC-eV/2,0>,<xV/2,yV/2+rC+eV/2,eV>}
                cylinder{0,eV*z,rC+eV/2 translate <-xV/2,yV/2,0>}
                cylinder{0,eV*z,rC+eV/2 translate <xV/2,yV/2,0>}
                cylinder{0,eV*z,rC+eV/2 translate <-xV/2,-yV/2,0>}
                cylinder{0,eV*z,rC+eV/2 translate <xV/2,-yV/2,0>}
                scale <1,1,-1>
                translate z*eV/2
            }
            translate z*zV
        }
        union{
            box{<-xV/2-rC-eV/2,-yV/2,0>,<xV/2+rC+eV/2,yV/2,eV>}
            box{<-xV/2,-yV/2-rC-eV/2,0>,<xV/2,yV/2+rC+eV/2,eV>}
            cylinder{0,eV*z,rC+eV/2 translate <-xV/2,yV/2,0>}
            cylinder{0,eV*z,rC+eV/2 translate <xV/2,yV/2,0>}
            cylinder{0,eV*z,rC+eV/2 translate <-xV/2,-yV/2,0>}
            cylinder{0,eV*z,rC+eV/2 translate <xV/2,-yV/2,0>}
            #declare yH=yV*0.7;
            #declare zH=eV*2;
            difference{
                box{0,<eV,yH,zH> }
                union{
                    cylinder{-x*eV/2,x*eV*2,zH/2 translate y*zH}
                    cylinder{-x*eV/2,x*eV*2,zH/2 translate y*(yH-zH)}
                    box{<-eV/2,zH,-zH/2>,<eV*2,yH-zH,zH/2>}
                    translate <0,0,zH>
                }                     
                translate <0.65*xV/2,-yV*0.2,0>
                scale <0.5,1,-1>
            }
            translate z*eV
            texture{pigment{image_map{gif "newsmap_1"}} finish{F_Newspaper} translate <-0.5,-0.5,0> scale <xV+rC*2,yV+rC*2,1>}
        }
        
        texture{T_VMHead} 
        translate <0,yF+yV/2,-zV/2>
    }      
    difference{  
        superellipsoid{<0.3,0.3>}
        plane{y,-0.5}
        plane{y,0.5 inverse}
        scale <xF*0.5,yF,xF*0.5>
        translate y*yF/2
        texture{T_VMFoot}
    }                   
    #declare VMFootElement=union{
        cylinder{-x,x,rC}
        box{<-1,-rC*2,-rC>,<1,0,rC>}
        rotate x*10
    }                                
    union{  
        box{<-xV/2,-1,-zV/2>,<xV/2,rC,zV/2>}
        sphere{0,rC*0.5 translate <xV/2-rC,rC,zV/2-rC>}
        sphere{0,rC*0.5 translate <-xV/2+rC,rC,zV/2-rC>}
        sphere{0,rC*0.5 translate <xV/2-rC,rC,-zV/2+rC>}
        sphere{0,rC*0.5 translate <-xV/2+rC,rC,-zV/2+rC>}
        difference{object{VMFootElement scale <xV,1,1>}plane{x,0 rotate y*45 translate -x*xV/2}plane{x,0 rotate -y*45 inverse translate x*xV/2} translate -z*zV/2}
        difference{object{VMFootElement scale <xV,1,1>}plane{x,0 rotate y*45 translate -x*xV/2}plane{x,0 rotate -y*45 inverse translate x*xV/2} scale <1,1,-1> translate z*zV/2}
        difference{object{VMFootElement scale <zV,1,1>}plane{x,0 rotate y*45 translate -x*zV/2}plane{x,0 rotate -y*45 inverse translate z*zV/2} rotate y*-90 translate x*xV/2}
        difference{object{VMFootElement scale <zV,1,1>}plane{x,0 rotate y*45 translate -x*zV/2}plane{x,0 rotate -y*45 inverse translate z*zV/2} rotate y*90 translate -x*xV/2}
        translate y*rC
        scale <1.2,0.4,1.2>
        texture{T_VMFoot}
    }
    scale 0.6/xV
}                             

union{
    object{NVM_UT translate -x*2}
    object{NVM2 translate <-0.8,0,0.1>}
    object{NVM3}
    object{NVM4 translate <0.8,0,-0.1>}
    translate <24,0.25,-1>
    scale 0.55
}    


//-------------------------------------------------------------------------FIN DEL CODIGO DE LAS CAJAS DE NOTICIAS-------------------------------------


//-------------------------------------------------------------------------COMIENZO DEL CODIGO DEL CARRITO---------------------------------------------

#declare RadOK=2; // 0=no radiosity ; 1= low quality rad; 2= good quality
#declare ObjectOK=1; // turns object on
#declare AreaOK=1; // area light
global_settings {
    max_trace_level 5
    //---------------------------------------
    // change gamma if necessary (scene too bright for instance)
    //---------------------------------------
    assumed_gamma 1
    //---------------------------------------
    noise_generator 1
    #if (RadOK>0)
        radiosity{
            #switch (RadOK)
                #case (1)
                    count 35 error_bound 1.8 
                #break
                #case (2)
                    count 100 error_bound 0.1 
                #break
            #end    
            nearest_count 5 
            recursion_limit 1  
            low_error_factor 0.2 
            gray_threshold 0 
            minimum_reuse 0.015 
            brightness 1 
            adc_bailout 0.01/2      
            normal on
            media off
        }
    #end
}

//sky_sphere{pigment{gradient y color_map{[0.5 White*7][0.7 rgb <92,126,202>*7/225]}}}
sky_sphere{pigment{gradient y color_map{[0.3 White][0.6 rgb <92,126,202>/225]}}}

#declare T_Handles=texture{pigment{Orange} finish{ambient 0 diffuse 1 specular 0.3 roughness 0.1}}
#declare T_HandleBar=texture{pigment{rgb <0.2,0.4,0.8>} finish{ambient 0 diffuse 1 specular 1 roughness 0.001 reflection {0,0.8 fresnel}}}
#declare T_Wheel=texture{pigment{bozo lambda 3 scale 5 color_map{[0 rgb <0.9,0.93,0.91>*0.7][1 rgb <0.64,0.62,0.59>*0.5]}}finish{ambient 0 diffuse 1}}
#declare T_Rubber=texture{pigment{Black} finish{ambient 0 diffuse 1 specular 0.2 roughness 0.1}}
#declare T_Shiny=texture{
    pigment {color rgb 0.1} 
    finish{ambient 0 diffuse 1 metallic brilliance 4 specular 1 roughness 0.02 reflection {0.8,1}}
}    
#declare T_Rusty=texture{
    pigment {bozo turbulence 1 color_map{[0.3 DarkWood*0.5][0.5 DarkBrown*0.5]}} 
    normal{bozo turbulence 1 lambda 4 bump_size 1 scale 1/50}
    finish{ambient 0 diffuse 1 specular 0.01 roughness 0.1}
} 

#declare T_Metal=texture{
    bozo turbulence 1 lambda 4
    texture_map{
        [0.3 T_Shiny]
        [0.7 T_Rusty]
//        [0.5 pigment{Red}]
//        [0.5 pigment{Blue}]
    }
    scale 50
}
#if (ObjectOK=1)

    
    #include "cart_handles.inc"
    #include "cart_handlebar.inc"
    #include "cart_basket.inc"
    #include "cart_door.inc"
    #include "cart_frontleftwheel.inc"
    #include "cart_frontrightwheel.inc"
    #include "cart_backleftwheel.inc"
    #include "cart_backrightwheel.inc"
    #declare AxisFrontLeft=<-13.037,0,42.858>;
    #declare AxisFrontRight=<13.037,0,42.858>;
    #declare AxisBackLeft=<-26.393,0,-30.6>;
    #declare AxisBackRight=<26.393,0,-30.6>;
    
    // The wheels can be rotated independently
    #declare AngleFrontLeft=20;
    #declare AngleFrontRight=-6;
    #declare AngleBackLeft=15;
    #declare AngleBackRight=-80;
    
    #declare Cart=union{
    
        object{basket}
        object{door}
        object{handles}
        object{handlebar}
        
        object{frontleftwheel translate -AxisFrontLeft rotate y*AngleFrontLeft translate AxisFrontLeft}
        object{frontrightwheel translate -AxisFrontRight rotate y*AngleFrontRight translate AxisFrontRight}
        object{backleftwheel translate -AxisBackLeft rotate y*AngleBackLeft translate AxisBackLeft}
        object{backrightwheel translate -AxisBackRight rotate y*AngleBackRight translate AxisBackRight}
    }
#else
    #declare Cart=box{<-30,1,-30>,<30,80,30> texture{T_Metal}}

#end


object{Cart  rotate x*-10  rotate y*10 rotate z*90 translate <1450,45,-320> scale 0.009}    


//------------------------------------------------------------------------FIN DEL CODIGO DEL CARRITO----------------------------------------------------------



//----------------------------------------------------------------------COMIENZO DEL CODIGO DEL EXTINTOR------------------------------------------------------

#include "functions.inc"
// =========================================
// Textures
// -----------------------------------------
#declare C_Red= color rgb <1,0.2, 0.05>;
#declare sc=0; // règle le niveau de reflectivité
#declare C_Copper=Copper;
#declare F_Paint=finish{ambient 0 diffuse 0.7 specular 1 roughness 1/30}
#declare F_Copper=finish{ambient 0 diffuse 0.4 
    metallic brilliance 2 
    specular 1 roughness 1/10
}
#declare T_Copper=texture{
    pigment{
        crackle solid      
        turbulence 0.2
        color_map{
            [0 C_Copper*1.8]
            [1 C_Copper]
        }
    }
    finish{F_Copper}
} 
#declare T_Copper2=texture{T_Copper
    normal{crackle solid turbulence 0.2}
} 
#declare T_Copper3=texture{T_Copper
    normal{wrinkles bump_size 0.2}
} 
#declare P_Paint0=pigment{
    crackle solid
    turbulence 0.1
    color_map{
        [0 C_Red*0.1]
        [1 C_Red*0.2]
    }
}          
#declare P_Paint1=pigment{
    crackle solid
    turbulence 0.1
    color_map{
        [0 C_Red*0.3]
        [1 C_Red*0.5]
    }
}          
#declare P_Paint2=pigment{
    crackle solid
    turbulence 0.1
    color_map{
        [0 C_Red*1.7]
        [1 C_Red*1.2]
    }
}                  
#declare T_PaintTop=texture{
    pigment{
        gradient y
        pigment_map{
            [0 P_Paint1]
            [1 P_Paint2]
        }
    }
    finish{F_Paint}
}                           
#declare T_Top_1_1=texture{
    pigment{
        gradient y
        turbulence 0.1
        poly_wave 0.3
        lambda 4           
        color_map{[0 C_Copper*0.1][1 C_Copper*0.5]}
    }
    finish{F_Copper}
} 
#declare k=0.02; // parameter controlling the penetration of the top paint layer : the smaller the more rusty
#declare turb=0.008;
#declare T_Top_1_2=texture{
    spherical
    turbulence turb
    lambda 3
    texture_map{
        [k*0.5 T_PaintTop]   // external layer
        [k*0.5  T_Copper]
        [k*1 T_Copper]
        [k*5 T_Copper3 scale 0.01 ] // internal layer
    }
}                                                      
#declare T_Top_1_2a=texture{
    spherical
    turbulence turb
    lambda 3
    texture_map{
        [k*0.7 T_PaintTop]   // external
        [k*0.7  T_Copper]
        [k*1 T_Copper]
//                [k*5 T_Copper3 scale 0.1] // internal
        [k*2 T_PaintTop] // internal
    }
}                                                      
#declare T_Top_1_3=texture{
    pigment{
        gradient y
        poly_wave 3
        color_map{
            [0 C_Copper]
            [0.6 C_Copper]
            [0.7 C_Copper*0.5]
            [1 C_Copper*0.3]
        }
    }
    finish{F_Copper}
} 
#declare T_Top=texture{
    gradient y   
    turbulence 0.2
    lambda 4
    //warp{reset_children}
    texture_map{
        [0 T_Top_1_1]
        [0.05 T_Top_1_2a]
        [0.7 T_Top_1_2a]
        [0.8 T_Top_1_3]
        [1 T_Top_1_3]
    }                                        
}
#declare T_Paint=texture{
    pigment{P_Paint2}
    finish{F_Paint}
}                           
#declare T_CopperBase=texture{
    pigment{       
        gradient y
        pigment_map{
            [0 color C_Copper*0.1]
            [1 crackle solid turbulence 0.1 color_map{[0 C_Copper*2][1 C_Copper]}]
        }
    }
    normal{crackle solid turbulence 0.1}
    finish{F_Copper}
} 
#declare T_PaintBase=texture{
    pigment{P_Paint1}
    normal{crackle solid bump_size 1 scale 0.1}
    finish{F_Paint}
}                           
#declare T_Body_1=texture{
    pigment{
        gradient y
        pigment_map{
            [0 P_Paint0 scale 0.1*<1,1/4,1>]
            [0.7 P_Paint2 scale 0.1*<1,1/4,1>]
            [1 color Black scale 0.1*<1,1/4,1>]
        }
    }          
    finish{F_Paint}
}                           
#declare T_Body_2=texture{
    pigment{
        gradient y
        pigment_map{
            [0 P_Paint0 scale 0.1*<1,1/4,1>]
            [1 P_Paint2 scale 0.1*<1,1/4,1>]
        }
    }          
    normal{wrinkles bump_size 0.2 scale 0.1*<1,1/4,1>}
    finish{F_Paint}
} 
#declare T_Body=texture{
    #declare k=0.012; // parameter controlling the penetration of the top paint layer : the smaller the more rusty
    cylindrical
    turbulence 0.006
    lambda 3
    texture_map{
        [k*0.65 T_Body_1 ]   // external
        [k*0.66  T_Copper scale <1,1/4,1>]
        [k*1 T_Copper3 scale <1,1/4,1>]
        [k*3 T_Body_2 ] // internal
    }
}                     
#declare T_Plug=texture{
    gradient x
    turbulence 0.3
    lambda 4
//    warp{reset_children}
    texture_map{
        [0 T_Paint scale 0.1]               
        [0.2 T_Paint scale 0.1]               
        [0.3 T_Copper scale 1/5]                
    }
}
#declare T_Base=texture{
    #declare k=0.2;
    cylindrical
    turbulence 0.3
    lambda 4
    texture_map{
        [k*0.8 T_CopperBase scale <0.1,1,0.1>] // Externe
        [k*1.1 T_PaintBase] // Interne
    }
}
// ============================
// Macros
// ============================

#macro rounded_bar(corner1, corner2, R)

union {
    box{ <corner1.x, corner1.y+R, corner1.z+R>, <corner2.x,corner2.y-R, corner2.z-R> }
    box{ <corner1.x+R, corner1.y, corner1.z+R>, <corner2.x-R,corner2.y, corner2.z-R> }
    box{ <corner1.x+R, corner1.y+R, corner1.z>, <corner2.x-R,corner2.y-R, corner2.z> }
    sphere { 0, R translate <corner1.x+R, corner1.y+R, corner1.z+R> }
    sphere { 0, R translate <corner1.x+R, corner1.y+R, corner2.z-R> }
    sphere { 0, R translate <corner1.x+R, corner2.y-R, corner1.z+R> }
    sphere { 0, R translate <corner1.x+R, corner2.y-R, corner2.z-R> }
    sphere { 0, R translate <corner2.x-R, corner1.y+R, corner1.z+R> }
    sphere { 0, R translate <corner2.x-R, corner1.y+R, corner2.z-R> }
    sphere { 0, R translate <corner2.x-R, corner2.y-R, corner1.z+R> }
    sphere { 0, R translate <corner2.x-R, corner2.y-R, corner2.z-R> }
    cylinder { <corner1.x+R, corner1.y+R, corner1.z+R>, <corner1.x+R,corner1.y+R, corner2.z-R>, R }
    cylinder { <corner1.x+R, corner1.y+R, corner1.z+R>, <corner1.x+R,corner2.y-R, corner1.z+R>, R }
    cylinder { <corner1.x+R, corner1.y+R, corner1.z+R>, <corner2.x-R,corner1.y+R, corner1.z+R>, R }
    cylinder { <corner1.x+R, corner1.y+R, corner2.z-R>, <corner1.x+R,corner2.y-R, corner2.z-R>, R }

    cylinder { <corner1.x+R, corner1.y+R, corner2.z-R>, <corner2.x-R,corner1.y+R, corner2.z-R>, R }
    cylinder { <corner2.x-R, corner1.y+R, corner1.z+R>, <corner2.x-R,corner1.y+R, corner2.z-R>, R }
    cylinder { <corner2.x-R, corner1.y+R, corner1.z+R>, <corner2.x-R,corner2.y-R, corner1.z+R>, R }
    cylinder { <corner2.x-R, corner1.y+R, corner2.z-R>, <corner2.x-R,corner2.y-R, corner2.z-R>, R }

    cylinder { <corner1.x+R, corner2.y-R, corner1.z+R>, <corner1.x+R,corner2.y-R, corner2.z-R>, R }
    cylinder { <corner1.x+R, corner2.y-R, corner1.z+R>, <corner2.x-R,corner2.y-R, corner1.z+R>, R }
    cylinder { <corner1.x+R, corner2.y-R, corner2.z-R>, <corner2.x-R,corner2.y-R, corner2.z-R>, R }
    cylinder { <corner2.x-R, corner2.y-R, corner1.z+R>, <corner2.x-R,corner2.y-R, corner2.z-R>, R }
}

#end

#macro O_Screw(sc)
intersection {
    box { -x-z, x+y+z }
    box { -3*x-3*z, x+2*y+3*z rotate y*60 }
    box { -3*x-3*z, x+2*y+3*z rotate y*120 }
    box { -3*x-3*z, x+2*y+3*z rotate y*240 }
    box { -3*x-3*z, x+2*y+3*z rotate y*300 }
    scale sc
}
#end

// ============================
// Fire hydrant
// ============================
#declare r0=0.02;
#declare s0=3;
#declare haut1 = 9.3;
#declare rayon1 = 10*sqrt(1-pow(haut1/10,2));
#declare fpig=function{pigment{wrinkles}}
#declare F_Top = union {
    union {
        cylinder { 0, .3*y, 11.8 }
        cylinder { .3*y, 2*y, 12 }
        difference {             
//                        sphere {0, 1} // original sphere
            isosurface{
                function{f_sphere(x,y,z,1) - fpig(x*s0,y*s0,z*s0).gray*r0}
                contained_by {box{-1,1}}
                max_gradient 1
            }
            
            #declare i = 0;
            #declare n=8;
            #while (i <n/2)
                torus { 1.5, 0.57
                    rotate x*90
                    scale <1,1,0.7>
                    rotate y*i*360/n
                    scale <1,1.11,1>
                }
                #declare i = i + 1;
            #end 
            
            texture{T_Top}
            scale 10
            translate 2*y
        }
        cylinder { haut1*y, 9.8*y, rayon1 translate 2*y }
    }
    union {
        object {
            O_Screw(<rayon1*.8, 1, rayon1*.8>)
            translate 9.8*y
            translate 2*y
        }
        object {
            rounded_bar(<-rayon1*.4, -.2, -rayon1*.4>,<rayon1*.4, 2, rayon1*.4>, .2)
            translate 10.8*y
            translate 2*y
        }
    }
}


#declare F_Body = union {
    union {                     
        union{
            torus { 1,1/6 scale <12, 6, 12> translate 1*y }
            cylinder { 0, 1*y, 12*(1+1/6) }
            cylinder { 0, 2*y, 12 }
            cone { 2*y, 11, 3*y, 10 }
            texture{T_Base scale <13,3,13>}
        }
        #declare tmp = 6;
        #while (tmp > 0)
            #declare tmp = tmp - 1;
            object {
                O_Screw(<1, 1, 1>)
                translate 2.01*y +  11.5*x
                rotate y*360*tmp/6
                texture {T_Top_1_3 scale 0.1}
            }
        #end
        difference {
//                        cylinder {0.3*y, 4*y, 1 } // original cylinder
            isosurface{
                function{pow(x,2)+pow(z,2)-1 + (1 - fpig(x*s0,y*s0,z*s0).gray)*r0}
                contained_by {box{<-1,0.3,-1>,<1,4,1>}}
                max_gradient 2.424
            }
            
            #declare tmp = 20;
            #while (tmp >0)
                #declare tmp = tmp - 1;
                union {
                    sphere { 0, 0.2 }
                    cylinder { 0, 1.9*y, 0.2 }
                    sphere { 1.9*y, 0.2 }
                    translate <1.17,0.4,0>
                    rotate y*360*tmp/20
                }
            #end
            
            scale <1,1/4,1>
            texture{T_Body}
            scale <10,40,10>
        } 
        union {
            cylinder {0, 7*x, 5  texture{T_Plug scale 7} translate x*8}
            cylinder {0, 7*x, 5  texture{T_Plug scale 7} translate x*8 rotate y*180}
            cylinder { 0, 8*x, 6  texture{T_Plug scale 8} translate x*8 rotate y*90}
            translate y*30
        }           
        
        cylinder { 38*y, 39*y, 10.5 }
        cylinder { 39*y, 40*y, 11 }
    }
    union {
        superellipsoid { <.2,1>
            clipped_by { box {<-1.1,0,-1.1>, <1.1,1.1,1.1>} }
            scale <6.2, 3, 6.2>
        }
        superellipsoid { <.3,1>
            clipped_by { box {<-1.1,0,-1.1>, <1.1,1.1,1.1>} }
            scale <3.5, 1, 3.5>
            translate 3*y
        }
        object {
            O_Screw(<1.7, 1, 1.7>)
            translate 4*y
        }   
        rotate -90*x
        translate 30*y - 16*z
    }
    union {
        superellipsoid { <.25,1>
            clipped_by { box {<-1.1,0,-1.1>, <1.1,1.1,1.1>} }
            scale <5.2, 2, 5.2>
        }
        superellipsoid { <.3,1>
            translate 2*y
            scale <3, 1, 3>
        }
        object {
            O_Screw(<1.7, 1, 1.7>)
            translate 3*y
        }
        rotate -90*x
        rotate -90*y
        translate 30*y + 15*x
    }
    union {
        superellipsoid { <.3,1>
            clipped_by { box {<-1.1,0,-1.1>, <1.1,1.1,1.1>} }
            scale <5.2, 2, 5.2>
        }
        superellipsoid { <.3,1>
            translate 2*y
            scale <3, 1, 3>
        }
        object {
            O_Screw(<1.7, 1, 1.7>)
            translate 3*y
        }
        rotate -90*x
        rotate 90*y
        translate 30*y - 15*x
    }
}

// ============================
// A link
// ============================
#declare link_object = union {
   torus {.7, .3 clipped_by {box {<-1, -.3, -1>, <0, .3, 1>}} translate -x* .6}
   torus {.7, .3 clipped_by {box {<-1, -.3, -1>, <0, .3, 1>}} translate -x* .6 scale <-1, 1, 1>}
   cylinder {-x*.6, x*.6, .3 translate z * .7}
   cylinder {-x*.6, x*.6, .3 translate -z * .7}
   scale .5
}


// ============================
// Chris Colefax parameters
// ============================
#declare link_looseness = 15;
#declare link_count = 20;
#declare link_twist = .475;

#declare camera_sky = y-.01*x;
#declare link_point1 = <10, 25.2, 0>;
#declare link_point2 = <17, 28, 0>;
#declare O_Chaine1 = object { #include "link.inc"}

#declare camera_sky = y+.01*x;
#declare link_point1 = <-10, 25.2, 0>;
#declare link_point2 = <-17, 28, 0>;
#declare O_Chaine2 = object{O_Chaine1 scale <-1,1,1>}

#declare link_looseness = 14;
#declare link_count = 22;
#declare camera_sky = y+.01*z;
#declare link_point1 = <0, 24.5, -10>;
#declare link_point2 = <0, 27, -19>;
#declare O_Chaine3 = object { #include "link.inc"}


#declare FireHydrant = union {
    object { F_Top translate y*40 }
    object { F_Body }
    object { O_Chaine1 }
    object { O_Chaine2 }
    object { O_Chaine3 }
    texture{T_Copper2}
}

object { FireHydrant rotate y*45 scale 0.012  translate <4,0.2,-1.75>}