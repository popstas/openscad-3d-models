// Smoke tests for pure functions: node --import tsx --test src/core.test.ts
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { extractModelName, isIndexableModel, toStl, toPng, ModelMeta } from './render-core';
import { sanitizeSlug, todayStamp } from './create-project';

test('extractModelName parses // 3D: marker and description var', () => {
  const src = [
    '// 3D: my great model',
    'description = "Holder for things";',
    'base_x = 10;',
  ].join('\n');
  assert.deepEqual(extractModelName(src), { name: 'my great model', description: 'Holder for things' });
});

test('extractModelName returns empty fields when markers absent', () => {
  assert.deepEqual(extractModelName('cube(1);'), { name: '', description: '' });
});

function meta(scadRel: string, name = 'n', description = 'd'): ModelMeta {
  return { name, description, scadRel, previews: [] };
}

test('isIndexableModel accepts a regular model', () => {
  assert.equal(isIndexableModel(meta('models/2025-01-01-thing/thing.scad')), true);
});

test('isIndexableModel skips modules.scad', () => {
  assert.equal(isIndexableModel(meta('models/modules.scad')), false);
});

test('isIndexableModel skips template folders', () => {
  assert.equal(isIndexableModel(meta('models/template-default/default.scad')), false);
});

test('isIndexableModel skips unsubstituted placeholders', () => {
  assert.equal(isIndexableModel(meta('models/2025-01-01-x/x.scad', '${longName}', 'd')), false);
  assert.equal(isIndexableModel(meta('models/2025-01-01-x/x.scad', 'n', '${shortDescription}')), false);
});

test('toStl / toPng derive output paths next to the scad', () => {
  assert.equal(toStl('a/b/model.scad'), 'a/b/model.stl');
  assert.match(toPng('a/b/model.scad', 'iso').replace(/\\/g, '/'), /a\/b\/preview\.iso\.png$/);
});

test('sanitizeSlug produces kebab-case', () => {
  assert.equal(sanitizeSlug('  My Great_Model!  '), 'my-great-model');
  assert.equal(sanitizeSlug('--a--b--'), 'a-b');
});

test('todayStamp is YYYY-MM-DD', () => {
  assert.match(todayStamp(), /^\d{4}-\d{2}-\d{2}$/);
});
