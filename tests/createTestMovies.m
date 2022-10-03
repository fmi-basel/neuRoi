function movieStructList = createTestMovies()
    movieStructList = {};
    movieStructList{1} = createMovie();
    affineMat2 = [1 0 0; 0 1 0; -3 2 1];
    movieStructList{2}= createMovie('ampList', [2, 2, 3], 'affineMat', affineMat2);
    affineMat3 = [1.2 0 0; 0.33 1 0; 2 3 1];
    movieStructList{3}= createMovie('ampList', [2, 2, 3], 'affineMat', affineMat3);
end
