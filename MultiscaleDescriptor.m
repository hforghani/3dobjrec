classdef MultiscaleDescriptor
    %MULTISCALEDESCRIPTOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        frames_array;
        descriptors_array;
    end
    
    methods
        function self = MultiscaleDescriptor(frames_array, descriptors_array)
            self.frames_array = frames_array;
            self.descriptors_array = descriptors_array;
        end
        
    end
    
end

