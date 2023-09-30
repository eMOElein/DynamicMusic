import os
import shutil
from time import gmtime, strftime

buildPath = ".build.mohidden"
projectPath = ".build.mohidden/project"
buildName = "DynamicMusic-" +strftime("%Y%m%d%H%M%S", gmtime())

os.chdir("..")

if os.path.isdir(buildPath):
  shutil.rmtree(buildPath)

os.makedirs(buildPath)
os.makedirs(projectPath)

shutil.copyfile("DynamicMusic.omwscripts", projectPath +"/DynamicMusic.omwscripts")
shutil.copytree("scripts", projectPath +"/scripts")
shutil.make_archive(buildPath +"/" +buildName, 'zip', projectPath)
