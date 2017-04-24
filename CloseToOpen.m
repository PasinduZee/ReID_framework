function CloseToOpen
%CloseToOpen extention for close set re-id solution developed by
%Pasindu Kanchana ,Imesha Sudasingha,Madhawa Vidanapathirana and Jayan
%Vidanapathirana
%Any question on the CloseToOpen extension please contact us in:
%Pasindu Kanchana (pasinduk77@gmail.com)
%Any question regarding the re-id algorithms by Raphael Prates,please
%contact him in: Raphael Prates (pratesufop@gmail.com)


close all

addpath '.\KISSME'
addpath '.\auxiliary'
addpath '.\ranking_aggregation'
addpath '.\Algorithms'

%viper definitions
dataset = 'viper'; 
totN=632*0.75;


% To run the extention for KernelXCRC algorithm
C2O(dataset,totN);
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             