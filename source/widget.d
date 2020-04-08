module widget;

import core.stdc.stdio;

import dvector;

import types;
import primitives;

enum: int {
    TYPE_WINDOW,
    TYPE_SIZER,
    TYPE_WIDGET
}

struct Window {
    string id;

    Rect rect;

    Dvector!(Window*) children;

    bool hover = false;

    void* derived;

    auto as(T)(){
        return cast(T*)derived;
    }
    
    alias rect this;

    int typeId = TYPE_WINDOW;
}

enum {
    vertical,
    horizontal
}

struct Sizer {
    Window window;
    
    int orientation = vertical;

    uint padding = 5;

    alias window this;

    @nogc nothrow:

    this(string id, int or, Point pos, int w, int h){
        orientation = or;

        this.id = id;
        this.pos = pos;
        this.w = w;
        this.h = h;

        derived = &this;

        typeId = TYPE_SIZER;
    }

    this(string id, int or){
        orientation = or;

        this.id = id;

        derived = &this;

        typeId = TYPE_SIZER;
    }

    void add(ref Window child){
        children.pushBack(&child);
        layout();
    }

    void layout(){
        if(orientation == horizontal){
            foreach (i, ref child; children){
                child.w = cast(int)((this.w - (children.length + 1) * padding) / children.length);
                child.h = h;
                child.pos = Point(cast(int)(this.x + i * (child.w + padding) + padding), this.y);
                
                if(child.typeId == TYPE_SIZER){
                    child.as!Sizer.layout();
                }
            }
        }else{
            foreach (i, ref child; children){
                child.w = w;
                child.h = cast(int)((this.h - (children.length + 1) * padding) / children.length);
                child.pos = Point(this.x, cast(int)(this.y + i * (child.h + padding) + padding));
                
                if(child.typeId == TYPE_SIZER){
                    child.as!Sizer.layout();
                }
            }
        }
        
    }

    ~this(){
        children.clear;
    }

}

struct Widget {
    Window window;
    Color color = Color(0.5f, 0.5f, 0.5f);
    
    alias window this;

    @nogc nothrow:

    this(string id){
        this.id = id;
        
        derived = &this;

        typeId = TYPE_WIDGET;
    }
}

@nogc nothrow:

void draw(Window* obj){
    //if(obj.typeId == TYPE_SIZER)
    //    return;
    auto c = obj.as!Widget.color;
    if(obj.hover)
        drawRect!SOLID(obj.rect, c);
    else
        drawRect(obj.rect, c);
}

/// safe and fake recursion :)
void doItForAllWindows(Callback)(scope Callback cb, ref Dvector!(Window*) root){
    auto stack = root.save;
    while(!stack.empty){
        auto n = stack.length - 1;
        auto widget = stack[n];
        
        cb(widget);

        stack.popBack;
        if(widget.children.length){
            foreach (ref child; widget.children)
                stack.pushBack(child);
        }
    }
    stack.free;
}