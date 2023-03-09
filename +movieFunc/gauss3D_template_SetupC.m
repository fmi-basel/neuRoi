function [Gauss3DStack, templates_Gauss3D] = gauss3D_template_SetupC(stack, sigma)

    Gauss3DStack = imgaussfilt3(stack, sigma);
    templates_Gauss3D.template = mean(Gauss3DStack,3);
    templates_Gauss3D.maxtemplate = max(Gauss3DStack, [], 3);
    templates_Gauss3D.dftemplate = double(templates_Gauss3D.maxtemplate) - templates_Gauss3D.template;

end