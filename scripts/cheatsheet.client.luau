-- Flood Timelines Script - version 1 - cheatsheet
-- https://github.com/myralune/ftbs

--[===[
// Functions
create ("timeline", name: string) ( create_tl_props ): timeline                // make new timeline object
create ("xframe", name: string)   ( create_xf_props ): xframe                  // make new xframe object
macro (f: () -> {timeline | xframe})                                           // automate xframe/timeline creation
org.folder    (name: string)               ( container_props ): container      // create folder container
org.container (class: string,name: string) ( container_props ): container      // create container

// Types
type create_tl_props = {
	attributes: {[string]: any},
	target: Instance?
	onconditionfail: timeline?,
	xframe | container
}

type create_xf_props = {
	attributes: {[string]: any},
	target: Instance?
	onconditionfail: timeline?
}

type container_props = {
	attributes: {[string]: any},
	xframe
}

type  timeline = Configuration
type    xframe = ObjectValue
type container = Instance
]===]