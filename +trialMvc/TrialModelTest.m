classdef TrialModelTest < matlab.unittest.TestCase
    % Tests the TrialModel class
    properties
        model
        movieStruct
        tmpDir
    end
       
    methods(TestMethodSetup)
        function createTrial(self)
            tmpDir = 'tmp';
            if ~exist(tmpDir, 'dir')
                mkdir(tmpDir)
            end
            self.movieStruct = testUtils.createMovie();
            mockMovie.name = 'test_trial';
            mockMovie.rawMovie = self.movieStruct.rawMovie;
            mockMovie.meta.frameRate = 2;
            self.model = trialMvc.TrialModel('mockMovie', mockMovie);
            self.model.importRoisFromMask(self.movieStruct.mask);

            self.tmpDir = tmpDir;
            self.addTeardown(@rmdir, tmpDir, 's')
        end
    end

    methods(Test)
        function testCalcAnatomy (self)
            [mapData, mapOption] = self.model.calcAnatomy();
            self.verifyEqual(mapData, self.movieStruct.anatomy);
        end
        
        function testExtraceTimeTrace(self)
            [timeTraceMat, roiArr] = self.model.extractTimeTraceMat();
            self.verifyEqual(timeTraceMat, self.movieStruct.timeTraceMat);
        end
        
        function filePath = createRoiFreehandArrFile(self)
            roiArray = createRoiFreehandArr();
            filePath = fullfile(self.tmpDir, 'RoiFreehandArr.mat');
            save(filePath, 'roiArray')
        end
        
        function testLoadRoiFreehandArr(self)
            filePath = self.createRoiFreehandArrFile();
            imageSize = size(self.movieStruct.anatomy);
            
            self.model.loadRoiArr(filePath);
            self.verifyEqual(class(self.model.roiArr), 'roiFunc.RoiArray')
        end
                
    end

end


function roiArray = createRoiFreehandArr()
    positionList = {[3,3; 3,6; 6,6; 6,3], [2,7; 4,7; 4,10; 2,10]};
    roiArray = RoiFreehand.empty();
    for k=1:length(positionList)
        roiFh = RoiFreehand(positionList{k});
        roiFh.tag = k;
        roiArray(k) = roiFh;
    end
end

