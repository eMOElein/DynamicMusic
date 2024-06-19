import os
import shutil
import time

buildPath = ".build.mohidden"
projectPath = ".build.mohidden/project"
buildTime = time.time()
buildName = "DynamicMusic-" +str(int(buildTime))

os.chdir("..")

if os.path.isdir(buildPath):
  shutil.rmtree(buildPath)

os.makedirs(buildPath)
os.makedirs(projectPath)

shutil.copyfile("DynamicMusic.omwscripts", projectPath +"/DynamicMusic.omwscripts")
shutil.copyfile(".dev.mohidden/readme.url", projectPath +"/DynamicMusic_Readme.url")
shutil.copytree("scripts", projectPath +"/scripts")
shutil.make_archive(buildPath +"/" +buildName, 'zip', projectPath)
