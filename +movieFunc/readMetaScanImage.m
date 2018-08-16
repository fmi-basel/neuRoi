% Peter Rupprecht 02-2015 using Scanimage B data
% reads metadata and returns image info file and framerate, zstep,
% framerate, zoom, motorpositions, scalingfactors
% optional input is the -full- filename/path
% Modified by Bo Hu 2018-March
% simplified string search
% output meta structure only

function meta = readMetaScanImage(filename)
% READ_METADATA read meta data from TIFF file
% Example:
%     meta = read_metadata('examplePath/exampleFile.tif)

imgInfoArr = imfinfo(filename);
imgInfo = imgInfoArr(1);


%% define metadata of interest

snippet{1} = 'scanimage.SI4.scanFrameRate';
snippet{2} = 'scanimage.SI4.triggerOutDelay';
snippet{3} = 'scanimage.SI4.triggerOut';
snippet{4} = 'scanimage.SI4.stackZStepSize';
snippet{5} = 'scanimage.SI4.stackNumSlices';
snippet{6} = 'scanimage.SI4.scanPixelsPerLine';
snippet{7} = 'scanimage.SI4.scanZoomFactor';
snippet{8} = 'scanimage.SI4.scanLinesPerFrame';
snippet{9} = 'scanimage.SI4.savedBitdepthX';
snippet{10} = 'scanimage.SI4.triggerTime';
snippet{11} = 'scanimage.SI4.framerate_user';
snippet{12} = 'scanimage.SI4.framerate_user_check';
snippet{13} = 'scanimage.SI4.beamPowers';
snippet{14} = 'scanimage.SI4.beamLengthConstants';
snippet{15} = 'scanimage.SI4.autoscaleSavedImages';
snippet{16} = 'scanimage.SI4.acqNumFrames';
snippet{17} = 'scanimage.SI4.acqNumAveragedFrames';

snippet{18} = 'scanimage.SI4.motorPosition';
snippet{19} = 'scalingFactorAndOffset';
snippet{20} = 'framerate_precise';

%% read out metadata

imgDescription = imgInfo.ImageDescription;
imgDescription = strrep(imgDescription, ' framerate', [newline 'framerate']);
imgDescriptArr = strsplit(imgDescription, '\n');
imgDescriptArr = cellfun(@(x) strsplit(x, ' = '),imgDescriptArr, ...
                         'UniformOutput',false);

for ind = 1:size(snippet,2)
    entryExist{ind} = 0;
    for jnd = 1:size(imgDescriptArr,2)
        entry = imgDescriptArr{jnd};
        if strcmp(snippet{ind},entry{1})
            result{ind} = str2num(char(entry{2}));
            entryExist{ind} = 1;
        end
    end
    if ~entryExist{ind}
        result{ind} = NaN;
    end
end

%% make metadata it easier to process

if result{12}; framerate = min(result{11},result{1}); else framerate = result{1}; end
if ~isempty(result{20}); framerate = result{20}; end
meta.framerate = framerate;
meta.zstep = result{4};
meta.zoom = result{7};
meta.motorpositions = result{18};
meta.scalingfactors = result{19};
meta.height = imgInfo.Height;
meta.width = imgInfo.Width;
meta.numberframes = numel(imgInfoArr);
end
