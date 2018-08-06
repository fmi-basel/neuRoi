%% Add path
addpath('..');
%% Clear variables
clear all
%% Initialize model
mymodel = NrModel({'aa','bb'});
mycontroller = NrController(mymodel);
