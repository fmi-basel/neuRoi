function deleteDefaultFigureMenu(fig)
    set(0,'showhiddenhandles','on')
    tagArray = {'figMenuHelp','figMenuWindow','figMenuDesktop','figMenuTools',...
                'figMenuInsert','figMenuView','figMenuEdit','figMenuFile'};
    for k=1:length(tagArray)
        tag = tagArray{k};
        hobj = findobj(fig,'Tag',tag);
        delete(hobj)
    end
    set(0,'showhiddenhandles','off')

    
end

