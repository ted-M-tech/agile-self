'use client';

import { useState, useEffect } from 'react';
import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetDescription, SheetFooter } from './ui/sheet';
import { Button } from './ui/button';
import { Checkbox } from './ui/checkbox';
import { Input } from './ui/input';
import { Label } from './ui/label';
import { Calendar, CheckCircle2, Sparkles } from 'lucide-react';
import { getDeadlinePresets, getDefaultDeadline, getRelativeDateText } from '@/lib/date-utils';

interface TryItemWithAction {
  text: string;
  createAction: boolean;
  deadline?: string;
}

interface ActionItemsSheetProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  tryItems: TryItemWithAction[];
  onConfirm: (items: TryItemWithAction[]) => void;
}

export function ActionItemsSheet({ open, onOpenChange, tryItems, onConfirm }: ActionItemsSheetProps) {
  const [items, setItems] = useState<TryItemWithAction[]>([]);
  const presets = getDeadlinePresets();
  const [selectedPreset, setSelectedPreset] = useState<string | null>(null);

  // Initialize items when sheet opens
  useEffect(() => {
    if (open && tryItems.length > 0) {
      // Set all items to be selected by default with 7-day deadline
      const defaultDeadline = getDefaultDeadline();
      setItems(
        tryItems.map(item => ({
          ...item,
          createAction: true,
          deadline: item.deadline || defaultDeadline,
        }))
      );
      setSelectedPreset(null);
    }
  }, [open, tryItems]);

  const toggleItemAction = (index: number) => {
    setItems(prev =>
      prev.map((item, i) =>
        i === index ? { ...item, createAction: !item.createAction } : item
      )
    );
  };

  const updateDeadline = (index: number, deadline: string) => {
    setItems(prev =>
      prev.map((item, i) =>
        i === index ? { ...item, deadline } : item
      )
    );
    setSelectedPreset(null);
  };

  const applyPresetToAll = (presetValue: string) => {
    setItems(prev =>
      prev.map(item =>
        item.createAction ? { ...item, deadline: presetValue } : item
      )
    );
    setSelectedPreset(presetValue);
  };

  const handleConfirm = () => {
    onConfirm(items);
    onOpenChange(false);
  };

  const selectedCount = items.filter(item => item.createAction).length;

  return (
    <Sheet open={open} onOpenChange={onOpenChange}>
      <SheetContent side="bottom" className="h-[85vh] overflow-y-auto rounded-t-2xl">
        <SheetHeader className="mb-6">
          <SheetTitle className="flex items-center gap-2 text-xl">
            <Sparkles className="w-5 h-5 text-purple-600" />
            Turn into Action Items?
          </SheetTitle>
          <SheetDescription>
            Select which Try items to convert into trackable action items with deadlines
          </SheetDescription>
        </SheetHeader>

        {/* Quick Preset Buttons */}
        {selectedCount > 0 && (
          <div className="mb-6 p-4 bg-blue-50 rounded-lg border border-blue-200">
            <Label className="text-sm font-medium text-blue-900 mb-3 block">
              Quick Deadline Presets (applies to all selected)
            </Label>
            <div className="flex flex-wrap gap-2">
              {presets.map((preset) => (
                <Button
                  key={preset.label}
                  variant={selectedPreset === preset.value ? "default" : "outline"}
                  size="sm"
                  onClick={() => applyPresetToAll(preset.value)}
                  className={
                    selectedPreset === preset.value
                      ? "bg-blue-600 hover:bg-blue-700"
                      : "border-blue-300 text-blue-700 hover:bg-blue-100"
                  }
                >
                  {preset.label}
                </Button>
              ))}
            </div>
          </div>
        )}

        {/* Try Items List */}
        <div className="space-y-4 mb-6">
          {items.map((item, index) => (
            <div
              key={index}
              className={`p-4 rounded-lg border-2 transition-all ${
                item.createAction
                  ? 'bg-purple-50 border-purple-300'
                  : 'bg-gray-50 border-gray-200 opacity-60'
              }`}
            >
              {/* Checkbox and Try Item Text */}
              <div className="flex items-start gap-3 mb-3">
                <Checkbox
                  id={`try-${index}`}
                  checked={item.createAction}
                  onCheckedChange={() => toggleItemAction(index)}
                  className="mt-1"
                />
                <label
                  htmlFor={`try-${index}`}
                  className="flex-1 cursor-pointer text-slate-900 font-medium"
                >
                  {item.text}
                </label>
                {item.createAction && (
                  <CheckCircle2 className="w-5 h-5 text-purple-600 flex-shrink-0" />
                )}
              </div>

              {/* Deadline Picker (only shown when selected) */}
              {item.createAction && (
                <div className="ml-9 space-y-2">
                  <Label htmlFor={`deadline-${index}`} className="text-sm text-purple-700 flex items-center gap-2">
                    <Calendar className="w-4 h-4" />
                    Deadline
                  </Label>
                  <div className="flex items-center gap-3">
                    <Input
                      id={`deadline-${index}`}
                      type="date"
                      value={item.deadline || ''}
                      onChange={(e) => updateDeadline(index, e.target.value)}
                      className="flex-1 bg-white"
                    />
                    {item.deadline && (
                      <span className="text-sm text-purple-600 font-medium whitespace-nowrap">
                        {getRelativeDateText(item.deadline)}
                      </span>
                    )}
                  </div>
                </div>
              )}
            </div>
          ))}
        </div>

        {/* Summary and Actions */}
        <SheetFooter className="sticky bottom-0 bg-white pt-4 border-t border-slate-200 mt-auto">
          <div className="w-full space-y-3">
            <div className="text-center text-sm text-slate-600 bg-slate-50 p-3 rounded-lg">
              {selectedCount === 0 ? (
                "No action items selected"
              ) : (
                <>
                  Creating <span className="font-bold text-purple-600">{selectedCount}</span> action item{selectedCount !== 1 ? 's' : ''}
                </>
              )}
            </div>
            <div className="flex gap-3">
              <Button
                variant="outline"
                onClick={() => onOpenChange(false)}
                className="flex-1"
              >
                Cancel
              </Button>
              <Button
                onClick={handleConfirm}
                disabled={selectedCount === 0}
                className="flex-1 bg-purple-600 hover:bg-purple-700"
              >
                Confirm ({selectedCount})
              </Button>
            </div>
          </div>
        </SheetFooter>
      </SheetContent>
    </Sheet>
  );
}
