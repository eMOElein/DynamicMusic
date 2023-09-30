import os
import shutil

buildPath = ".build.mohidden"
projectPath = ".build.mohidden/project"

os.chdir("..")

if os.path.isdir(buildPath):
  shutil.rmtree(buildPath)

os.makedirs(buildPath)
os.makedirs(projectPath)

shutil.copyfile("DynamicMusic.omwscripts", projectPath +"/DynamicMusic.omwscripts")
shutil.copytree("scripts", projectPath +"/scripts")
shutil.make_archive(buildPath +"/build", 'zip', projectPath)
